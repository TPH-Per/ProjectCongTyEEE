<!-- RequisitionStats.vue -->
<template>
  <div class="requisition-stats grid grid-cols-1 lg:grid-cols-3 gap-6 p-5">
    <!-- Stat Cards (Left 2 cols) -->
    <div class="lg:col-span-2 space-y-6">
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <!-- Total -->
        <div class="stat-card total bg-muted border border-border rounded-xl p-4 text-center">
          <span class="stat-label block text-xs text-muted-foreground uppercase font-semibold">TỔNG YÊU CẦU</span>
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
          <span class="stat-val block text-3xl font-bold text-blue-600 mt-1">{{ stats.delivered }}</span>
        </div>
        <!-- Rejected -->
        <div class="stat-card rejected bg-red-100 border border-red-500/30 rounded-xl p-4 text-center">
          <span class="stat-label block text-xs text-red-500 uppercase font-semibold">BỊ TỪ CHỐI</span>
          <span class="stat-val block text-3xl font-bold text-red-600 mt-1">{{ stats.rejected }}</span>
        </div>
      </div>

      <!-- Type Distribution -->
      <div class="chart-section bg-card rounded-xl border border-border p-5">
        <h3 class="text-sm font-bold text-foreground uppercase mb-4">Phân Bố Theo Loại Phiếu</h3>
        <div class="space-y-3">
          <div>
            <div class="flex justify-between text-xs text-muted-foreground mb-1">
              <span>Xuất Kho (OUTBOUND):</span>
              <span class="font-bold text-red-500">{{ stats.outbound }} phiếu</span>
            </div>
            <div class="progress-bar-container bg-background h-2.5 rounded-full overflow-hidden">
              <div class="bg-red-500 h-full rounded-full" :style="{ width: `${getPercentage(stats.outbound)}%` }"></div>
            </div>
          </div>
          <div>
            <div class="flex justify-between text-xs text-muted-foreground mb-1">
              <span>Nhập Kho (INBOUND):</span>
              <span class="font-bold text-orange-500">{{ stats.inbound }} phiếu</span>
            </div>
            <div class="progress-bar-container bg-background h-2.5 rounded-full overflow-hidden">
              <div class="bg-orange-500 h-full rounded-full" :style="{ width: `${getPercentage(stats.inbound)}%` }"></div>
            </div>
          </div>
          <div>
            <div class="flex justify-between text-xs text-muted-foreground mb-1">
              <span>Trả Hàng (RETURN):</span>
              <span class="font-bold text-green-500">{{ stats.returnType }} phiếu</span>
            </div>
            <div class="progress-bar-container bg-background h-2.5 rounded-full overflow-hidden">
              <div class="bg-green-500 h-full rounded-full" :style="{ width: `${getPercentage(stats.returnType)}%` }"></div>
            </div>
          </div>
        </div>
      </div>

      <!-- High Demand Items -->
      <div class="bg-card rounded-xl border border-border p-5">
        <h3 class="text-sm font-bold text-foreground uppercase mb-3">Nguyên Liệu Được Yêu Cầu Nhiều Nhất</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div 
            v-for="(item, idx) in topItems" 
            :key="item.name"
            class="flex items-center gap-3 p-3 bg-background border border-border rounded-lg"
          >
            <span class="text-xl font-bold font-mono text-[#FF9800]">#{{ idx + 1 }}</span>
            <div>
              <span class="block text-sm font-semibold text-foreground">{{ item.name }}</span>
              <span class="block text-xs text-muted-foreground">Đã yêu cầu xuất: {{ item.totalQty }} {{ item.unit }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Audit Logs Side Panel (Right 1 col) -->
    <div class="audit-log bg-card rounded-xl border border-border p-5 flex flex-col max-h-[500px]">
      <h3 class="text-sm font-bold text-foreground uppercase mb-4 flex items-center gap-2">
        ⏳ NHẬT KÝ HOẠT ĐỘNG (AUDIT TRAIL)
      </h3>
      <div class="logs-container flex-1 overflow-y-auto space-y-4 pr-1">
        <div v-if="allLogs.length === 0" class="text-center py-8 text-muted-foreground text-sm">
          Chưa có nhật ký hoạt động nào.
        </div>
        <div 
          v-else 
          v-for="log in allLogs" 
          :key="log.id" 
          class="log-entry text-xs p-3 bg-background border border-border rounded-lg space-y-1"
        >
          <div class="flex justify-between text-muted-foreground font-mono">
            <span>👤 {{ log.actor }}</span>
            <span>{{ log.timestamp }}</span>
          </div>
          <p class="text-foreground font-medium">{{ log.action }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { Requisition } from '@/composables/useRequisition';

const props = defineProps<{
  requisitions: Requisition[];
}>();

const stats = computed(() => {
  const reqs = props.requisitions;
  const total = reqs.length;
  
  const pending = reqs.filter(r => r.status === 'PENDING').length;
  const approved = reqs.filter(r => r.status === 'APPROVED' || r.status === 'PROCESSING').length;
  const delivered = reqs.filter(r => r.status === 'COMPLETED').length;
  const rejected = reqs.filter(r => r.status === 'REJECTED' || r.status === 'CANCELLED').length;

  const outbound = reqs.filter(r => r.type === 'OUTBOUND').length;
  const inbound = reqs.filter(r => r.type === 'INBOUND').length;
  const returnType = reqs.filter(r => r.type === 'RETURN').length;

  return {
    total,
    pending,
    approved,
    delivered,
    rejected,
    outbound,
    inbound,
    returnType
  };
});

const getPercentage = (count: number) => {
  if (stats.value.total === 0) return 0;
  return Math.round((count / stats.value.total) * 100);
};

const topItems = computed(() => {
  const itemMap: Record<string, { name: string; unit: string; totalQty: number }> = {};
  
  props.requisitions.forEach(req => {
    if (req.requisition_items) {
      req.requisition_items.forEach(item => {
        const name = item.ingredients?.name_vi || 'Sản phẩm';
        if (!itemMap[name]) {
          itemMap[name] = {
            name: name,
            unit: item.unit,
            totalQty: 0
          };
        }
        itemMap[name].totalQty += item.requested_quantity;
      });
    }
  });

  return Object.values(itemMap)
    .sort((a, b) => b.totalQty - a.totalQty)
    .slice(0, 4);
});

// Aggregate basic logs from dates
const allLogs = computed(() => {
  const logs: Array<{ id: string; action: string; actor: string; timestamp: string }> = [];
  props.requisitions.forEach(req => {
    const actorName = req.requested_by_profile?.raw_user_meta_data?.full_name || 'Hệ thống';
    logs.push({
      id: `${req.id}-created`,
      action: `[Phiếu #${req.requisition_number}] Được tạo mới`,
      actor: actorName,
      timestamp: new Date(req.created_at).toLocaleString()
    });
    
    if (req.approved_at) {
      const approverName = req.approved_by_profile?.raw_user_meta_data?.full_name || 'Quản lý';
      logs.push({
        id: `${req.id}-approved`,
        action: `[Phiếu #${req.requisition_number}] Được phê duyệt`,
        actor: approverName,
        timestamp: new Date(req.approved_at).toLocaleString()
      });
    }
    
    if (req.status === 'COMPLETED' || req.status === 'REJECTED') {
      logs.push({
        id: `${req.id}-completed`,
        action: `[Phiếu #${req.requisition_number}] Đã cập nhật trạng thái ${req.status}`,
        actor: 'Hệ thống',
        timestamp: new Date(req.updated_at).toLocaleString()
      });
    }
  });

  return logs.sort((a, b) => {
    const timeA = new Date(a.timestamp).getTime();
    const timeB = new Date(b.timestamp).getTime();
    return timeB - timeA;
  });
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
