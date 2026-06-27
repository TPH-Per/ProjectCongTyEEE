<!-- RequisitionList.vue -->
<template>
  <div class="requisition-list">
    <div class="list-header">
      <h2 class="list-title">DANH SÁCH YÊU CẦU XUẤT KHO</h2>
      <button class="btn-new" @click="$emit('create')">
        <span>➕</span> Tạo Yêu Cầu Mới
      </button>
    </div>

    <!-- Filter Bar -->
    <div class="filter-bar">
      <div class="flex-1 min-w-[200px] relative">
        <label for="search-input" class="sr-only">Tìm kiếm yêu cầu</label>
        <input 
          id="search-input"
          v-model="searchQuery"
          type="text"
          placeholder="Tìm theo ID, người tạo, ghi chú..."
          class="filter-search w-full"
        />
      </div>
      <label for="station-filter" class="sr-only">Lọc theo bộ phận bếp</label>
      <select id="station-filter" v-model="filterStation" class="filter-select">
        <option value="all">Tất cả Bộ phận Bếp</option>
        <option value="Bếp Nướng">Bếp Nướng</option>
        <option value="Bếp Lẩu">Bếp Lẩu</option>
        <option value="Bếp Chiên">Bếp Chiên</option>
        <option value="Bếp Lạnh">Bếp Lạnh</option>
        <option value="Quầy Bar">Quầy Bar</option>
      </select>
      <label for="status-filter" class="sr-only">Lọc theo trạng thái</label>
      <select id="status-filter" v-model="filterStatus" class="filter-select">
        <option value="all">Tất cả Trạng thái</option>
        <option value="pending">Chờ duyệt</option>
        <option value="approved">Đã duyệt</option>
        <option value="delivered">Đã giao</option>
        <option value="rejected">Từ chối</option>
      </select>
    </div>

    <!-- Requisition Items Grid -->
    <div class="requisitions-container pr-1">
      <div v-if="filteredRequisitions.length === 0" class="text-center py-12 text-gray-500 bg-[#2D2D2D] rounded-xl border border-[#404040]">
        📭 Không tìm thấy phiếu yêu cầu xuất kho nào khớp với bộ lọc.
      </div>
      <div v-else class="space-y-4">
        <RequisitionCard 
          v-for="req in filteredRequisitions" 
          :key="req.id" 
          :requisition="req" 
          @select="$emit('select', req)"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import type { Requisition } from '@/stores/kitchen';
import RequisitionCard from './RequisitionCard.vue';

const props = defineProps<{
  requisitions: Requisition[];
}>();

const emit = defineEmits<{
  (e: 'create'): void;
  (e: 'select', requisition: Requisition): void;
}>();

const searchQuery = ref('');
const filterStation = ref('all');
const filterStatus = ref('all');

const filteredRequisitions = computed(() => {
  return props.requisitions.filter(req => {
    // Search filter
    const matchesSearch = 
      req.id.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      req.actor.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      req.notes.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      req.items.some(i => i.name.toLowerCase().includes(searchQuery.value.toLowerCase()));

    // Station filter
    const matchesStation = filterStation.value === 'all' || req.station === filterStation.value;

    // Status filter
    const matchesStatus = filterStatus.value === 'all' || req.status === filterStatus.value;

    return matchesSearch && matchesStation && matchesStatus;
  });
});
</script>

<style scoped>
.requisition-list {
  padding: 20px;
}

.list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.list-title {
  font-size: 20px;
  font-weight: 700;
  color: #FFFFFF;
}

.btn-new {
  background: #FF9800;
  color: white;
  padding: 10px 20px;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s ease;
}

.btn-new:hover {
  background: #F57C00;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(255, 152, 0, 0.2);
}

.btn-new:active {
  transform: translateY(0);
}

/* Filter Bar */
.filter-bar {
  display: flex;
  gap: 12px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.filter-select,
.filter-search {
  padding: 10px 14px;
  background: #1A1A1A;
  border: 1px solid #404040;
  border-radius: 8px;
  color: #FFFFFF;
  font-size: 13px;
  outline: none;
  transition: all 0.2s ease;
}

.filter-select:focus,
.filter-search:focus {
  border-color: #FF9800;
}

.filter-search {
  min-width: 240px;
}
</style>
