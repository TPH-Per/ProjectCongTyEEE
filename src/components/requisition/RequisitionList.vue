<!-- RequisitionList.vue -->
<template>
  <div class="requisition-list">
    <div class="list-header">
      <h2 class="list-title">{{ t('req.title') }}</h2>
      <button class="btn-new" @click="$emit('create')">
        <span>➕</span> {{ t('req.create') }}
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
      <label for="type-filter" class="sr-only">Lọc theo loại</label>
      <select id="type-filter" v-model="filterType" class="filter-select">
        <option value="all">Tất cả Loại Phiếu</option>
        <option value="OUTBOUND">{{ t('req.type.outbound') }}</option>
        <option value="INBOUND">{{ t('req.type.inbound') }}</option>
        <option value="RETURN">{{ t('req.type.return') }}</option>
      </select>
      <label for="status-filter" class="sr-only">Lọc theo trạng thái</label>
      <select id="status-filter" v-model="filterStatus" class="filter-select">
        <option value="all">Tất cả Trạng thái</option>
        <option value="PENDING">{{ t('req.status.pending') }}</option>
        <option value="PROCESSING">{{ t('req.status.processing') }}</option>
        <option value="APPROVED">{{ t('req.status.approved') }}</option>
        <option value="COMPLETED">{{ t('req.status.completed') }}</option>
        <option value="CANCELLED">{{ t('req.status.cancelled') }}</option>
        <option value="REJECTED">{{ t('req.status.rejected') }}</option>
      </select>
    </div>

    <!-- Requisition Items Grid -->
    <div class="requisitions-container pr-1">
      <div v-if="filteredRequisitions.length === 0" class="text-center py-12 text-muted-foreground bg-card rounded-xl border border-border">
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
import type { Requisition } from '@/composables/useRequisition';
import RequisitionCard from './RequisitionCard.vue';
import { useLanguageStore } from '@/stores/useLanguageStore';

const { t } = useLanguageStore();

const props = defineProps<{
  requisitions: Requisition[];
}>();

const emit = defineEmits<{
  (e: 'create'): void;
  (e: 'select', requisition: Requisition): void;
}>();

const searchQuery = ref('');
const filterType = ref('all');
const filterStatus = ref('all');

const filteredRequisitions = computed(() => {
  return props.requisitions.filter(req => {
    // Search filter
    const matchesSearch = 
      req.requisition_number.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      (req.requested_by_profile?.raw_user_meta_data?.full_name || '').toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      (req.note || '').toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      (req.requisition_items || []).some(i => (i.ingredients?.name_vi || '').toLowerCase().includes(searchQuery.value.toLowerCase()));

    // Type filter
    const matchesType = filterType.value === 'all' || req.type === filterType.value;

    // Status filter
    const matchesStatus = filterStatus.value === 'all' || req.status === filterStatus.value;

    return matchesSearch && matchesType && matchesStatus;
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
