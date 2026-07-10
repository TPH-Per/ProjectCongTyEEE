<template>
  <div class="floor-plan-container">
    <div class="floor-plan-header">
      <h2>Sơ đồ bàn - Sảnh</h2>
      <div class="filters">
        <select v-model="selectedArea" class="filter-select">
          <option value="all">Tất cả khu vực</option>
          <option v-for="area in areas" :key="area" :value="area">
            Khu vực {{ area }}
          </option>
        </select>
      </div>
    </div>

    <div v-if="tables.length === 0" class="no-tables">
      Không tìm thấy dữ liệu bàn. Vui lòng kiểm tra lại thiết lập chi nhánh.
    </div>

    <div v-else class="tables-grid">
      <div 
        v-for="table in filteredTables" 
        :key="table.id"
        :class="['table-card', `status-${table.status}`]"
        @click="selectTable(table)"
      >
        <div class="table-code">{{ table.code }}</div>
        <div class="table-status">{{ getStatusText(table.status) }}</div>
        <div v-if="table.customer" class="table-customer">{{ table.customer }}</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'

const props = defineProps<{
  tables: any[]
}>()

const emit = defineEmits<{
  selectTable: [tableCode: string]
}>()

const selectedArea = ref('all')

const areas = computed(() => {
  const codes = new Set(props.tables.map(t => t.code.charAt(0).toUpperCase()))
  return Array.from(codes).filter(c => c >= 'A' && c <= 'Z').sort()
})

const filteredTables = computed(() => {
  if (selectedArea.value === 'all') return props.tables
  return props.tables.filter(t => t.code.toUpperCase().startsWith(selectedArea.value))
})

function getStatusText(status: string): string {
  const statusMap: Record<string, string> = {
    'available': 'Trống',
    'occupied': 'Đang dùng món',
    'reserved': 'Đã đặt bàn',
    'maintenance': 'Bảo trì'
  }
  return statusMap[status] || status
}

function selectTable(table: any) {
  // Let the user select the table to either open it or add orders to it
  emit('selectTable', table.code)
}
</script>

<style scoped>
.floor-plan-container {
  padding: 20px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
}

.floor-plan-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #e5e7eb;
  padding-bottom: 16px;
  margin-bottom: 20px;
}

.floor-plan-header h2 {
  font-size: 18px;
  font-weight: 800;
  color: #111827;
  margin: 0;
}

.filter-select {
  padding: 8px 16px;
  border-radius: 8px;
  border: 1px solid #d1d5db;
  background-color: white;
  font-size: 14px;
  font-weight: 600;
  color: #374151;
  outline: none;
  cursor: pointer;
}

.filter-select:focus {
  border-color: #f97316;
}

.tables-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 16px;
}

.no-tables {
  text-align: center;
  padding: 40px;
  color: #6b7280;
  font-weight: 600;
}

.table-card {
  padding: 24px 16px;
  border-radius: 12px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s ease-in-out;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.table-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.table-card.status-available {
  background: #ecfdf5;
  border: 2px solid #34d399;
}

.table-card.status-occupied {
  background: #fef2f2;
  border: 2px solid #f87171;
}

.table-card.status-reserved {
  background: #fffbeb;
  border: 2px solid #fbbf24;
}

.table-card.status-maintenance {
  background: #f3f4f6;
  border: 2px solid #9ca3af;
}

.table-code {
  font-size: 24px;
  font-weight: 900;
  margin-bottom: 6px;
  color: #1f2937;
}

.table-status {
  font-size: 12px;
  font-weight: 700;
  color: #4b5563;
}

.table-customer {
  font-size: 11px;
  color: #4b5563;
  margin-top: 4px;
  font-weight: 600;
  background: rgba(255, 255, 255, 0.6);
  padding: 2px 6px;
  border-radius: 4px;
  display: inline-block;
}
</style>
