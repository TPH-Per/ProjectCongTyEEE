<!-- RequisitionCard.vue -->
<template>
  <div 
    class="requisition-card"
    :class="[
      `status-${requisition.status.toLowerCase()}`
    ]"
    @click="$emit('select', requisition)"
    role="button"
    :aria-label="`Yêu cầu ${requisition.requisition_number} loại ${requisition.type}, trạng thái ${getStatusLabel(requisition.status)}`"
    tabindex="0"
    @keydown.enter="$emit('select', requisition)"
  >
    <div class="card-header">
      <span class="card-id">#{{ requisition.requisition_number }}</span>
      <span class="card-date font-mono">{{ new Date(requisition.created_at).toLocaleString() }}</span>
    </div>
    
    <div class="flex justify-between items-center my-2">
      <div class="card-station font-semibold text-foreground">
        🏷️ {{ requisition.type }}
      </div>
      <span class="card-status" :class="`status-${requisition.status.toLowerCase()}`">
        {{ getStatusLabel(requisition.status) }}
      </span>
    </div>

    <div class="card-meta text-xs text-muted-foreground">
      <span>Người yêu cầu: <strong>{{ requisition.requested_by_profile?.raw_user_meta_data?.full_name || 'Người dùng' }}</strong></span>
    </div>

    <div class="card-items text-sm text-muted-foreground line-clamp-2 mt-2">
      📦 <span v-for="(item, idx) in requisition.requisition_items" :key="item.id">
        {{ item.ingredients?.name_vi || 'Sản phẩm' }} ({{ item.requested_quantity }}{{ item.unit }}){{ (requisition.requisition_items && idx < requisition.requisition_items.length - 1) ? ', ' : '' }}
      </span>
    </div>

    <div v-if="requisition.status === 'REJECTED' && requisition.rejection_reason" class="card-reason mt-2 text-xs">
      <strong>Lý do từ chối:</strong> {{ requisition.rejection_reason }}
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Requisition } from '@/composables/useRequisition';

const props = defineProps<{
  requisition: Requisition;
}>();

const emit = defineEmits<{
  (e: 'select', requisition: Requisition): void;
}>();

const getStatusLabel = (status: Requisition['status']) => {
  switch (status) {
    case 'PENDING': return 'Chờ duyệt';
    case 'PROCESSING': return 'Đang xử lý';
    case 'APPROVED': return 'Đã duyệt';
    case 'COMPLETED': return 'Đã giao';
    case 'CANCELLED': return 'Đã hủy';
    case 'REJECTED': return 'Từ chối';
    default: return status;
  }
};
</script>

<style scoped>
.requisition-card {
  background: #2D2D2D;
  border: 2px solid #404040;
  border-radius: 12px;
  padding: 16px;
  margin-bottom: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
  outline: none;
}

.requisition-card:hover {
  border-color: #616161;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}

.requisition-card:focus-visible {
  outline: 3px solid #2196F3;
  outline-offset: 2px;
}

/* Priority & Status Borders */
.requisition-card.status-pending {
  border-left: 4px solid #FF9800;
}

.requisition-card.status-processing {
  border-left: 4px solid #9C27B0;
}

.requisition-card.status-approved {
  border-left: 4px solid #4CAF50;
}

.requisition-card.status-completed {
  border-left: 4px solid #2196F3;
}

.requisition-card.status-rejected,
.requisition-card.status-cancelled {
  border-left: 4px solid #F44336;
  opacity: 0.8;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-id {
  font-size: 16px;
  font-weight: 700;
  color: #FFFFFF;
}

.card-date {
  font-size: 13px;
  color: #B0B0B0;
}

.card-status {
  padding: 4px 12px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  color: white;
}

.card-status.status-pending {
  background: #FF9800;
}

.card-status.status-processing {
  background: #9C27B0;
}

.card-status.status-approved {
  background: #4CAF50;
}

.card-status.status-completed {
  background: #2196F3;
}

.card-status.status-rejected,
.card-status.status-cancelled {
  background: #F44336;
}

.card-reason {
  padding: 8px 12px;
  background: rgba(244, 67, 54, 0.1);
  border-left: 3px solid #F44336;
  border-radius: 4px;
  color: #FF8A80;
}

/* Animations */
@keyframes pulse-urgent-border {
  0%, 100% {
    box-shadow: 0 0 0 0 rgba(244, 67, 54, 0.4);
  }
  50% {
    box-shadow: 0 0 0 6px rgba(244, 67, 54, 0);
  }
}
</style>
