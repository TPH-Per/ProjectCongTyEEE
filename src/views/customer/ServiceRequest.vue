<!-- File: src/views/customer/ServiceRequest.vue -->
<template>
  <div class="w-full h-full flex flex-col overflow-hidden bg-[#3D2817]">
    
    <!-- Header -->
    <div class="px-6 md:px-8 py-4 bg-[#1a110a] border-b border-[#2d1e12] flex items-center justify-between shrink-0">
      <div>
        <h1 class="text-lg md:text-xl font-black text-white font-serif tracking-wide">Yêu cầu phục vụ</h1>
        <p class="text-[10px] text-gray-400 mt-0.5">Chọn loại dịch vụ hoặc thiết bị cần hỗ trợ thêm tại bàn</p>
      </div>
    </div>

    <!-- Main Split -->
    <div class="flex-1 flex flex-col lg:flex-row overflow-hidden">
      <!-- Request Options Grid (Wood background, scrollable) -->
      <div class="flex-1 overflow-y-auto p-6 md:p-8 flex items-center justify-center">
        <ServiceRequestGrid @submit="onSubmitRequest" />
      </div>

      <!-- Active Requests List Sidebar (Light Gray background panel) -->
      <div class="w-full lg:w-96 bg-[#F5F5F5] border-t lg:border-t-0 lg:border-l border-gray-300 p-6 md:p-8 flex flex-col overflow-hidden shrink-0 text-[#333333]">
        <h3 class="text-sm font-black text-[#333333] border-b border-gray-250 pb-3 flex items-center gap-2 mb-4 shrink-0 font-serif uppercase tracking-wider">
          <span>🔔</span> Nhật ký yêu cầu
        </h3>

        <!-- Scrollable list -->
        <div class="flex-1 overflow-y-auto flex flex-col gap-3">
          <!-- Empty State -->
          <div v-if="requests.length === 0" 
               class="flex-1 flex flex-col items-center justify-center text-center p-6 text-gray-400 gap-2 select-none">
            <span class="text-3xl">📭</span>
            <p class="text-[11px] font-bold text-gray-500">Chưa gửi yêu cầu hỗ trợ nào</p>
          </div>

          <!-- Request items (White background cards) -->
          <div v-for="req in requests" :key="req.id"
               class="bg-white border border-gray-200 rounded-xl p-4 flex flex-col gap-2.5 shadow-sm transition-all hover:shadow">
            <div class="flex items-start justify-between gap-2">
              <div class="flex items-center gap-2">
                <span class="text-2xl select-none">{{ getRequestEmoji(req.type) }}</span>
                <div>
                  <h4 class="text-xs font-bold text-[#333333]">
                    {{ store.translateRequestType(req.type) }}
                  </h4>
                  <p class="text-[9px] text-[#666666] font-bold mt-0.5">
                    Gửi lúc: {{ formatTime(req.createdAt) }}
                  </p>
                </div>
              </div>

              <!-- Status Badge -->
              <span :class="[
                'text-[9px] font-black px-2 py-0.5 rounded border uppercase tracking-wider',
                req.status === 'created' ? 'bg-amber-500/10 text-amber-600 border-amber-500/20' :
                req.status === 'waiting' ? 'bg-amber-500/10 text-amber-600 border-amber-500/20 animate-pulse' :
                req.status === 'processing' ? 'bg-blue-500/10 text-blue-500 border-blue-500/20' :
                req.status === 'completed' ? 'bg-emerald-500/10 text-emerald-600 border-emerald-500/20' :
                'bg-gray-100 text-gray-400 border-gray-200'
              ]">
                {{ getStatusLabel(req.status) }}
              </span>
            </div>

            <!-- Content if any -->
            <p v-if="req.content" class="text-[11px] text-[#666666] leading-relaxed bg-gray-50 p-2.5 rounded-lg border border-gray-150">
              <span class="text-[#E8772E] font-bold">Nội dung:</span> {{ req.content }}
            </p>

            <!-- Cancel Button for pending requests -->
            <div v-if="req.status === 'created' || req.status === 'waiting'" 
                 class="flex justify-end border-t border-gray-100 pt-2 mt-0.5">
              <button @click="cancelRequest(req.id)"
                      class="text-[10px] font-bold text-gray-500 hover:text-rose-500 bg-gray-50 hover:bg-rose-500/5 border border-gray-200 hover:border-rose-500/20 px-2.5 py-1 rounded transition-colors active:scale-95">
                Hủy yêu cầu
              </button>
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useCustomerStore } from '@/stores/customerStore';
import ServiceRequestGrid from '@/components/customer/ServiceRequestGrid.vue';
import type { ServiceRequestType } from '@/types/customer';

const store = useCustomerStore();
const router = useRouter();

const requests = computed(() => store.serviceRequests);

onMounted(() => {
  // BR-09: Require session
  if (!store.session) {
    router.push({ name: 'CustomerHome' });
  }
});

async function onSubmitRequest(data: { type: ServiceRequestType; content: string }) {
  await store.submitServiceRequest(data.type, data.content);
}

async function cancelRequest(id: string) {
  await store.cancelServiceRequest(id);
}

function getRequestEmoji(type: string): string {
  const emojis: Record<string, string> = {
    tissue: '🧻',
    bowl: '🥣',
    sauce: '🧂',
    ice: '🧊',
    grill_change: '🍳',
    charcoal_change: '🪵',
    request_bill: '💵',
    call_waiter: '🙋‍♂️',
    other: '✍️'
  };
  return emojis[type] || '🔔';
}

function getStatusLabel(status: string): string {
  const labels: Record<string, string> = {
    created: 'Đã gửi',
    waiting: 'Chờ nhận',
    accepted: 'Nhân viên nhận',
    processing: 'Đang làm',
    completed: 'Đã xong',
    cancelled: 'Đã hủy'
  };
  return labels[status] || status;
}

function formatTime(date: any): string {
  const d = new Date(date);
  return d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
}
</script>
