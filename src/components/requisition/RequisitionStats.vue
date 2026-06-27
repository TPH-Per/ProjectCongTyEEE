<!-- RequisitionStats.vue -->
<template>
  <div class="requisition-stats grid grid-cols-1 lg:grid-cols-3 gap-6 p-5">
    <!-- Stat Cards (Left 2 cols) -->
    <div class="lg:col-span-2 space-y-6">
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <!-- Total -->
        <div class="stat-card total bg-gray-800 border border-gray-700 rounded-xl p-4 text-center">
          <span class="stat-label block text-xs text-gray-400 uppercase font-semibold">TỔNG YÊU CẦU</span>
          <span class="stat-val block text-3xl font-bold text-foreground mt-1">{{ stats.total }}</span>
        </div>
        <!-- Pending -->
        <div class="stat-card pending bg-yellow-950/20 border border-yellow-500/30 rounded-xl p-4 text-center">
          <span class="stat-label block text-xs text-yellow-500 uppercase font-semibold">ĐANG CHỜ</span>
          <span class="stat-val block text-3xl font-bold text-[#FF9800] mt-1">{{ stats.pending }}</span>
        </div>
        <!-- Delivered -->
        <div class="stat-card delivered bg-blue-950/20 border border-blue-500/30 rounded-xl p-4 text-center">
          <span class="stat-label block text-xs text-blue-500 uppercase font-semibold">ĐÃ GIAO NHẬN</span>
          <span class="stat-val block text-3xl font-bold text-[#2196F3] mt-1">{{ stats.delivered }}</span>
        </div>
        <!-- Rejected -->
        <div class="stat-card rejected bg-red-950/20 border border-red-500/30 rounded-xl p-4 text-center">
          <span class="stat-label block text-xs text-red-500 uppercase font-semibold">BỊ TỪ CHỐI</span>
          <span class="stat-val block text-3xl font-bold text-[#F44336] mt-1">{{ stats.rejected }}</span>
        </div>
      </div>

      <!-- Priority Distribution -->
      <div class="chart-section bg-card rounded-xl border border-border p-5">
        <h3 class="text-sm font-bold text-gray-200 uppercase mb-4">Phân Bố Mức Độ Ưu Tiên</h3>
        <div class="space-y-3">
          <div>
            <div class="flex justify-between text-xs text-gray-400 mb-1">
              <span>Ưu tiên CAO (High):</span>
              <span class="font-bold text-red-500">{{ stats.highPriority }} phiếu</span>
            </div>
            <div class="progress-bar-container bg-background h-2.5 rounded-full overflow-hidden">
              <div class="bg-red-500 h-full rounded-full" :style="{ width: `${getPercentage(stats.highPriority)}%` }"></div>
            </div>
          </div>
          <div>
            <div class="flex justify-between text-xs text-gray-400 mb-1">
              <span>Ưu tiên TRUNG BÌNH (Medium):</span>
              <span class="font-bold text-orange-500">{{ stats.mediumPriority }} phiếu</span>
            </div>
            <div class="progress-bar-container bg-background h-2.5 rounded-full overflow-hidden">
              <div class="bg-orange-500 h-full rounded-full" :style="{ width: `${getPercentage(stats.mediumPriority)}%` }"></div>
            </div>
          </div>
          <div>
            <div class="flex justify-between text-xs text-gray-400 mb-1">
              <span>Ưu tiên THẤP (Low):</span>
              <span class="font-bold text-green-500">{{ stats.lowPriority }} phiếu</span>
            </div>
            <div class="progress-bar-container bg-background h-2.5 rounded-full overflow-hidden">
              <div class="bg-green-500 h-full rounded-full" :style="{ width: `${getPercentage(stats.lowPriority)}%` }"></div>
            </div>
          </div>
        </div>
      </div>

      <!-- High Demand Items -->
      <div class="bg-card rounded-xl border border-border p-5">
        <h3 class="text-sm font-bold text-gray-200 uppercase mb-3">Nguyên Liệu Được Yêu Cầu Nhiều Nhất</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div 
            v-for="(item, idx) in topItems" 
            :key="item.name"
            class="flex items-center gap-3 p-3 bg-background border border-border rounded-lg"
          >
            <span class="text-xl font-bold font-mono text-[#FF9800]">#{{ idx + 1 }}</span>
            <span class="text-2xl">{{ item.icon }}</span>
            <div>
              <span class="block text-sm font-semibold text-foreground">{{ item.name }}</span>
              <span class="block text-xs text-gray-400">Đã yêu cầu xuất: {{ item.totalQty }} {{ item.unit }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Audit Logs Side Panel (Right 1 col) -->
    <div class="audit-log bg-card rounded-xl border border-border p-5 flex flex-col max-h-[500px]">
      <h3 class="text-sm font-bold text-gray-200 uppercase mb-4 flex items-center gap-2">
        ⏳ NHẬT KÝ HOẠT ĐỘNG (AUDIT TRAIL)
      </h3>
      <div class="logs-container flex-1 overflow-y-auto space-y-4 pr-1">
        <div v-if="allLogs.length === 0" class="text-center py-8 text-gray-500 text-sm">
          Chưa có nhật ký hoạt động nào.
        </div>
        <div 
          v-else 
          v-for="log in allLogs" 
          :key="log.id" 
          class="log-entry text-xs p-3 bg-background border border-border rounded-lg space-y-1"
        >
          <div class="flex justify-between text-gray-400 font-mono">
            <span>👤 {{ log.actor }}</span>
            <span>{{ log.timestamp }}</span>
          </div>
          <p class="text-gray-200 font-medium">{{ log.action }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { Requisition } from '@/stores/kitchen';

const props = defineProps<{
  requisitions: Requisition[];
}>();

const stats = computed(() => {
  const reqs = props.requisitions;
  const total = reqs.length;
  
  const pending = reqs.filter(r => r.status === 'pending').length;
  const approved = reqs.filter(r => r.status === 'approved').length;
  const delivered = reqs.filter(r => r.status === 'delivered').length;
  const rejected = reqs.filter(r => r.status === 'rejected').length;

  const lowPriority = reqs.filter(r => r.priority === 'low').length;
  const mediumPriority = reqs.filter(r => r.priority === 'medium').length;
  const highPriority = reqs.filter(r => r.priority === 'high').length;

  return {
    total,
    pending,
    approved,
    delivered,
    rejected,
    lowPriority,
    mediumPriority,
    highPriority
  };
});

const getPercentage = (count: number) => {
  if (stats.value.total === 0) return 0;
  return Math.round((count / stats.value.total) * 100);
};

const topItems = computed(() => {
  const itemMap: Record<string, { icon: string; name: string; unit: string; totalQty: number }> = {};
  
  props.requisitions.forEach(req => {
    req.items.forEach(item => {
      if (!itemMap[item.name]) {
        itemMap[item.name] = {
          icon: item.icon,
          name: item.name,
          unit: item.unit,
          totalQty: 0
        };
      }
      itemMap[item.name].totalQty += item.requestedQty;
    });
  });

  return Object.values(itemMap)
    .sort((a, b) => b.totalQty - a.totalQty)
    .slice(0, 4);
});

// Aggregate all audit logs and sort by time desc
const allLogs = computed(() => {
  const logs: Array<{ id: string; action: string; actor: string; timestamp: string }> = [];
  props.requisitions.forEach(req => {
    req.auditLogs.forEach(log => {
      logs.push({
        ...log,
        action: `[Phiếu #${req.id}] ${log.action}`
      });
    });
  });

  return logs.sort((a, b) => b.timestamp.localeCompare(a.timestamp));
});
</script>

<style scoped>
.requisitions-stats {
  padding: 20px;
}

.stat-card {
  transition: all 0.2s ease;
}

.stat-card:hover {
  transform: translateY(-2px);
}

.logs-container::-webkit-scrollbar {
  width: 4px;
}

.logs-container::-webkit-scrollbar-thumb {
  background: #616161;
  border-radius: 2px;
}
</style>
