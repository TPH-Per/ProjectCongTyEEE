<!-- File: src/views/customer/ServiceRequest.vue -->
<template>
  <div class="service-request-layout">
    <!-- Header -->
    <div class="sr-header">
      <div class="header-content">
        <div class="header-icon">🔔</div>
        <div class="header-text">
          <h1 class="header-title">Yêu cầu phục vụ</h1>
          <p class="header-subtitle">
            Chọn loại dịch vụ hoặc thiết bị cần hỗ trợ tại bàn
          </p>
        </div>
      </div>
    </div>

    <!-- Main Split Layout -->
    <div class="sr-main">
      <!-- Left: Request Options Grid (3x3 = 9 buttons) -->
      <div class="sr-options-panel">
        <div class="options-grid">
          <button
            v-for="option in requestOptions"
            :key="option.type"
            class="option-card"
            :class="{ 'option-highlight': option.highlight }"
            @click="onSubmitRequest({ type: option.type, content: '' })"
          >
            <span class="option-emoji">{{ option.emoji }}</span>
            <span class="option-label">{{ option.label }}</span>
          </button>
        </div>
      </div>

      <!-- Right: Active Requests Sidebar -->
      <div class="sr-requests-panel">
        <div class="requests-header">
          <div class="requests-header-icon">📋</div>
          <h3 class="requests-header-title">Nhật ký yêu cầu</h3>
          <span class="requests-count">{{ requests.length }}</span>
        </div>

        <!-- Requests List - KHÔNG SCROLL -->
        <div class="requests-list">
          <!-- Empty State -->
          <div v-if="requests.length === 0" class="empty-state">
            <div class="empty-icon">📭</div>
            <h4 class="empty-title">Chưa có yêu cầu nào</h4>
            <p class="empty-subtitle">Các yêu cầu hỗ trợ sẽ hiển thị tại đây</p>
          </div>

          <!-- Request items - Max 5 cards -->
          <div
            v-for="req in visibleRequests"
            :key="req.id"
            class="request-card"
          >
            <div class="request-card-header">
              <div class="request-info">
                <span class="request-emoji">{{
                  getRequestEmoji(req.type)
                }}</span>
                <div class="request-details">
                  <h4 class="request-type">
                    {{ store.translateRequestType(req.type) }}
                  </h4>
                  <p class="request-time">🕐 {{ formatTime(req.createdAt) }}</p>
                </div>
              </div>

              <!-- Status Badge -->
              <span :class="['status-badge', `status-${req.status}`]">
                {{ getStatusLabel(req.status) }}
              </span>
            </div>

            <!-- Content if any -->
            <p v-if="req.content" class="request-content">
              <span class="content-label">Nội dung:</span>
              {{ req.content }}
            </p>

            <!-- Cancel Button -->
            <div
              v-if="req.status === 'created' || req.status === 'waiting'"
              class="request-actions"
            >
              <button @click="cancelRequest(req.id)" class="btn-cancel">
                ✕ Hủy yêu cầu
              </button>
            </div>
          </div>

          <!-- Show more indicator -->
          <div v-if="requests.length > 5" class="more-indicator">
            + {{ requests.length - 5 }} yêu cầu khác
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from "vue";
import { useRouter } from "vue-router";
import { useCustomerStore } from "@/stores/customerStore";
import type { ServiceRequestType } from "@/types/customer";

const store = useCustomerStore();
const router = useRouter();

const requests = computed(() => store.serviceRequests);

// ✅ Chỉ hiển thị tối đa 5 requests mới nhất
const visibleRequests = computed(() => {
  return requests.value.slice(0, 5);
});

// ✅ 9 loại yêu cầu (3x3 grid)
const requestOptions = [
  { type: "tissue" as ServiceRequestType, emoji: "🧻", label: "Khăn giấy" },
  { type: "bowl" as ServiceRequestType, emoji: "🥣", label: "Chén bát" },
  { type: "sauce" as ServiceRequestType, emoji: "🧂", label: "Gia vị" },
  { type: "ice" as ServiceRequestType, emoji: "🧊", label: "Thêm đá" },
  { type: "grill_change" as ServiceRequestType, emoji: "🍳", label: "Thay vỉ" },
  {
    type: "charcoal_change" as ServiceRequestType,
    emoji: "🪵",
    label: "Thay than",
  },
  {
    type: "request_bill" as ServiceRequestType,
    emoji: "💵",
    label: "Tính tiền",
    highlight: true,
  },
  {
    type: "call_waiter" as ServiceRequestType,
    emoji: "🙋‍♂️",
    label: "Gọi NV",
    highlight: true,
  },
  { type: "other" as ServiceRequestType, emoji: "✍️", label: "Khác" },
];

onMounted(() => {
  // BR-09: Require session
  if (!store.session) {
    router.push({ name: "CustomerHome" });
  }
});

async function onSubmitRequest(data: {
  type: ServiceRequestType;
  content: string;
}) {
  await store.submitServiceRequest(data.type, data.content);
}

async function cancelRequest(id: string) {
  await store.cancelServiceRequest(id);
}

function getRequestEmoji(type: string): string {
  const emojis: Record<string, string> = {
    tissue: "🧻",
    bowl: "🥣",
    sauce: "🧂",
    ice: "🧊",
    grill_change: "🍳",
    charcoal_change: "🪵",
    request_bill: "💵",
    call_waiter: "🙋‍♂️",
    other: "✍️",
  };
  return emojis[type] || "🔔";
}

function getStatusLabel(status: string): string {
  const labels: Record<string, string> = {
    created: "Đã gửi",
    waiting: "Chờ nhận",
    accepted: "Đã nhận",
    processing: "Đang xử lý",
    completed: "Hoàn thành",
    cancelled: "Đã hủy",
  };
  return labels[status] || status;
}

function formatTime(date: any): string {
  const d = new Date(date);
  return d.toLocaleTimeString("vi-VN", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}
</script>

<style scoped>
/* ✅ LAYOUT CHÍNH - KHÔNG SCROLL */
.service-request-layout {
  width: 100%;
  height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden; /* ✅ Ngăn scroll toàn bộ */
  background: linear-gradient(135deg, #2c1810 0%, #3d2817 100%);
  font-family:
    "Inter",
    -apple-system,
    BlinkMacSystemFont,
    sans-serif;
}

/* ✅ HEADER - CỐ ĐỊNH HEIGHT */
.sr-header {
  height: 80px;
  padding: 0 32px;
  background: linear-gradient(135deg, #1a110a 0%, #2d1e12 100%);
  border-bottom: 2px solid #e8772e;
  flex-shrink: 0;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
  display: flex;
  align-items: center;
}

.header-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.header-icon {
  font-size: 32px;
  filter: drop-shadow(0 2px 4px rgba(232, 119, 46, 0.5));
}

.header-text {
  display: flex;
  flex-direction: column;
}

.header-title {
  font-size: 22px;
  font-weight: 800;
  color: #fffbf5;
  margin: 0;
  letter-spacing: 0.5px;
  font-family: "Playfair Display", serif;
}

.header-subtitle {
  font-size: 11px;
  color: #b8a089;
  margin: 2px 0 0 0;
  font-weight: 500;
}

/* ✅ MAIN SPLIT LAYOUT */
.sr-main {
  flex: 1;
  display: flex;
  overflow: hidden; /* ✅ Không scroll */
  gap: 0;
  min-height: 0; /* ✅ Quan trọng cho flex */
}

/* ✅ LEFT PANEL: Options Grid (3x3) */
.sr-options-panel {
  flex: 1;
  padding: 24px;
  background: linear-gradient(180deg, #3d2817 0%, #2c1810 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden; /* ✅ Không scroll */
}

/* ✅ Grid 3x3 - Fit hoàn toàn */
.options-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  grid-template-rows: repeat(3, 1fr);
  gap: 16px;
  width: 100%;
  max-width: 700px;
  height: 100%;
  max-height: 500px;
}

/* ✅ Option Card */
.option-card {
  background: linear-gradient(135deg, #fffbf5 0%, #faf3e8 100%);
  border: 2px solid #e8dcc8;
  border-radius: 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
  padding: 12px;
  min-height: 0; /* ✅ Cho phép shrink */
}

.option-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 20px rgba(232, 119, 46, 0.3);
  border-color: #e8772e;
}

.option-card:active {
  transform: scale(0.95);
}

.option-card.option-highlight {
  background: linear-gradient(135deg, #e8772e 0%, #f5a623 100%);
  border-color: #e8772e;
}

.option-card.option-highlight .option-label {
  color: white;
}

.option-emoji {
  font-size: 48px;
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.1));
}

.option-label {
  font-size: 14px;
  font-weight: 700;
  color: #3d2817;
  text-align: center;
  line-height: 1.2;
}

/* ✅ RIGHT PANEL: Requests Sidebar */
.sr-requests-panel {
  width: 400px;
  background: linear-gradient(180deg, #faf3e8 0%, #f5efe6 100%);
  border-left: 3px solid #e8772e;
  display: flex;
  flex-direction: column;
  overflow: hidden; /* ✅ Không scroll */
  flex-shrink: 0;
  box-shadow: -4px 0 20px rgba(0, 0, 0, 0.15);
}

/* Requests Header */
.requests-header {
  height: 60px;
  padding: 0 20px;
  background: linear-gradient(135deg, #e8772e 0%, #f5a623 100%);
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
  box-shadow: 0 2px 8px rgba(232, 119, 46, 0.3);
}

.requests-header-icon {
  font-size: 22px;
}

.requests-header-title {
  font-size: 14px;
  font-weight: 800;
  color: #fffbf5;
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 1px;
  flex: 1;
}

.requests-count {
  background: rgba(255, 255, 255, 0.25);
  color: white;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 800;
}

/* ✅ Requests List - KHÔNG SCROLL */
.requests-list {
  flex: 1;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  overflow: hidden; /* ✅ Không scroll */
  min-height: 0;
}

/* ✅ EMPTY STATE */
.empty-state {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 20px;
  gap: 8px;
}

.empty-icon {
  font-size: 48px;
  opacity: 0.6;
}

.empty-title {
  font-size: 14px;
  font-weight: 700;
  color: #3d2817;
  margin: 0;
}

.empty-subtitle {
  font-size: 11px;
  color: #8b7355;
  margin: 0;
  line-height: 1.4;
}

/* ✅ REQUEST CARD - COMPACT */
.request-card {
  background: #fffbf5;
  border: 1px solid #e8dcc8;
  border-radius: 10px;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  transition: all 0.2s ease;
  box-shadow: 0 2px 6px rgba(61, 40, 23, 0.08);
  flex-shrink: 0; /* ✅ Không co lại */
}

.request-card:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(61, 40, 23, 0.15);
  border-color: #e8772e;
}

.request-card-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 10px;
}

.request-info {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  flex: 1;
  min-width: 0;
}

.request-emoji {
  font-size: 24px;
  flex-shrink: 0;
}

.request-details {
  flex: 1;
  min-width: 0;
}

.request-type {
  font-size: 13px;
  font-weight: 700;
  color: #3d2817;
  margin: 0 0 2px 0;
  line-height: 1.2;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.request-time {
  font-size: 10px;
  color: #8b7355;
  margin: 0;
  font-weight: 600;
}

/* ✅ STATUS BADGES */
.status-badge {
  font-size: 9px;
  font-weight: 800;
  padding: 3px 8px;
  border-radius: 5px;
  text-transform: uppercase;
  letter-spacing: 0.3px;
  white-space: nowrap;
  border: 1px solid;
  flex-shrink: 0;
}

.status-created {
  background: #fff4e6;
  color: #e8772e;
  border-color: #ffd9b3;
}

.status-waiting {
  background: #fff4e6;
  color: #e8772e;
  border-color: #ffd9b3;
  animation: pulse 2s infinite;
}

.status-accepted {
  background: #e6f4ff;
  color: #1890ff;
  border-color: #bae7ff;
}

.status-processing {
  background: #e6f7ff;
  color: #1890ff;
  border-color: #91d5ff;
  animation: pulse 2s infinite;
}

.status-completed {
  background: #f6ffed;
  color: #52c41a;
  border-color: #b7eb8f;
}

.status-cancelled {
  background: #f5f5f5;
  color: #8c8c8c;
  border-color: #d9d9d9;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.6;
  }
}

/* ✅ REQUEST CONTENT */
.request-content {
  font-size: 11px;
  color: #5c4a35;
  line-height: 1.4;
  background: #faf3e8;
  padding: 8px;
  border-radius: 6px;
  border-left: 2px solid #e8772e;
  margin: 0;
}

.content-label {
  color: #e8772e;
  font-weight: 700;
  margin-right: 4px;
}

/* ✅ REQUEST ACTIONS */
.request-actions {
  display: flex;
  justify-content: flex-end;
  padding-top: 6px;
  border-top: 1px solid #f0e6d8;
}

.btn-cancel {
  font-size: 10px;
  font-weight: 700;
  color: #8b7355;
  background: #faf3e8;
  border: 1px solid #e8dcc8;
  padding: 4px 10px;
  border-radius: 5px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 3px;
}

.btn-cancel:hover {
  color: #c62828;
  background: #fff5f5;
  border-color: #ffcdd2;
}

/* ✅ MORE INDICATOR */
.more-indicator {
  text-align: center;
  font-size: 11px;
  font-weight: 700;
  color: #e8772e;
  padding: 8px;
  background: rgba(232, 119, 46, 0.1);
  border-radius: 6px;
  margin-top: auto;
}

/* ✅ RESPONSIVE */
@media (max-width: 1024px) {
  .sr-main {
    flex-direction: column;
  }

  .sr-requests-panel {
    width: 100%;
    height: 200px;
    border-left: none;
    border-top: 3px solid #e8772e;
  }

  .sr-options-panel {
    flex: 1;
  }

  .options-grid {
    max-height: none;
    height: 100%;
  }
}

@media (max-width: 768px) {
  .sr-header {
    height: 70px;
    padding: 0 20px;
  }

  .header-title {
    font-size: 18px;
  }

  .header-subtitle {
    font-size: 10px;
  }

  .sr-options-panel {
    padding: 16px;
  }

  .options-grid {
    gap: 10px;
  }

  .option-emoji {
    font-size: 36px;
  }

  .option-label {
    font-size: 12px;
  }

  .requests-list {
    padding: 12px;
    gap: 8px;
  }

  .request-card {
    padding: 10px;
  }
}
</style>
