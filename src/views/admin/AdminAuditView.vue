<template>
  <div class="p-6 max-w-7xl mx-auto h-full flex flex-col">
    <div class="mb-6 flex flex-col md:flex-row justify-between md:items-end gap-4">
      <div>
        <h1 class="text-3xl font-bold text-gray-800 mb-2 flex items-center gap-2">
          <span class="text-[#FF7B89]">🕵️</span> Nhật Ký Hoạt Động (Audit Log)
        </h1>
        <p class="text-gray-500">Giám sát mọi thao tác và thay đổi dữ liệu trong hệ thống</p>
      </div>
      
      <div class="flex gap-2">
        <button class="kawaii-btn-ghost flex items-center gap-2">
          <span>⬇️</span> Xuất báo cáo
        </button>
      </div>
    </div>

    <!-- Filters -->
    <div class="kawaii-card p-4 mb-6 grid grid-cols-1 md:grid-cols-5 gap-4 shadow-sm border border-gray-50">
      <div class="md:col-span-2 relative">
        <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">🔍</span>
        <input type="text" placeholder="Tìm kiếm theo ID, payload..." class="kawaii-input w-full pl-11" />
      </div>
      <div>
        <select class="kawaii-input w-full bg-white appearance-none cursor-pointer">
          <option value="">🗓️ Tất cả thời gian</option>
          <option value="today">Hôm nay</option>
          <option value="week">Tuần này</option>
          <option value="month">Tháng này</option>
        </select>
      </div>
      <div>
        <select class="kawaii-input w-full bg-white appearance-none cursor-pointer">
          <option value="">⚡ Tất cả hành động</option>
          <option value="create">Tạo mới (CREATE)</option>
          <option value="update">Cập nhật (UPDATE)</option>
          <option value="delete">Xóa (DELETE)</option>
          <option value="login">Đăng nhập (LOGIN)</option>
        </select>
      </div>
      <div>
        <select class="kawaii-input w-full bg-white appearance-none cursor-pointer">
          <option value="">📦 Tất cả đối tượng</option>
          <option value="order">Đơn hàng</option>
          <option value="user">Người dùng</option>
          <option value="menu">Thực đơn</option>
          <option value="kpi">KPI</option>
        </select>
      </div>
    </div>

    <!-- Table -->
    <div class="kawaii-card flex-1 flex flex-col overflow-hidden shadow-sm border border-gray-50">
      <div class="overflow-x-auto flex-1">
        <table class="w-full text-left border-collapse min-w-[900px]">
          <thead class="bg-pink-50/30 sticky top-0 z-10 backdrop-blur-md">
            <tr class="text-gray-600 border-b border-pink-100">
              <th class="py-4 px-6 font-semibold text-sm">Thời gian</th>
              <th class="py-4 px-6 font-semibold text-sm">Nhánh</th>
              <th class="py-4 px-6 font-semibold text-sm">Người dùng</th>
              <th class="py-4 px-6 font-semibold text-sm">Hành động</th>
              <th class="py-4 px-6 font-semibold text-sm">Loại đối tượng</th>
              <th class="py-4 px-6 font-semibold text-sm">ID</th>
              <th class="py-4 px-6 font-semibold text-sm w-1/3">Payload (Chi tiết)</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="log in auditLogs" :key="log.id" class="border-b border-gray-50 hover:bg-pink-50/20 transition-colors">
              <td class="py-3 px-6 text-sm text-gray-500 whitespace-nowrap">{{ log.time }}</td>
              <td class="py-3 px-6 text-sm text-gray-800 font-medium">
                <span class="px-2.5 py-1 bg-gray-100/80 rounded-lg text-xs border border-gray-200/50">{{ log.branch }}</span>
              </td>
              <td class="py-3 px-6 text-sm">
                <div class="flex items-center gap-2.5">
                  <div class="w-7 h-7 rounded-xl bg-gradient-to-br from-pink-100 to-pink-200 text-[#FF7B89] flex items-center justify-center font-bold text-xs shadow-sm">
                    {{ log.user.charAt(0).toUpperCase() }}
                  </div>
                  <span class="font-medium text-gray-700">{{ log.user }}</span>
                </div>
              </td>
              <td class="py-3 px-6">
                <span :class="{
                  'px-3 py-1 rounded-full text-[11px] font-bold tracking-wide uppercase': true,
                  'bg-green-100/80 text-green-700 border border-green-200': log.action === 'CREATE',
                  'bg-blue-100/80 text-blue-700 border border-blue-200': log.action === 'UPDATE',
                  'bg-red-100/80 text-red-700 border border-red-200': log.action === 'DELETE',
                  'bg-purple-100/80 text-purple-700 border border-purple-200': log.action === 'LOGIN'
                }">
                  {{ log.action }}
                </span>
              </td>
              <td class="py-3 px-6 text-sm text-gray-700 font-medium">{{ log.entityType }}</td>
              <td class="py-3 px-6 text-sm text-gray-500 font-mono bg-gray-50/50 rounded">{{ log.entityId }}</td>
              <td class="py-3 px-6">
                <div class="bg-gray-50/80 p-2.5 rounded-xl text-xs font-mono text-gray-600 overflow-hidden text-ellipsis whitespace-nowrap max-w-xs border border-gray-200/60 shadow-inner" :title="log.payload">
                  {{ log.payload }}
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="p-4 border-t border-gray-100 flex justify-between items-center bg-white rounded-b-3xl">
        <span class="text-sm text-gray-500 font-medium">Hiển thị 1-10 trên 150 kết quả</span>
        <div class="flex gap-1.5">
          <button class="w-8 h-8 flex items-center justify-center rounded-xl border border-gray-200 text-gray-500 hover:bg-gray-50 hover:border-gray-300 transition-all disabled:opacity-50">&lt;</button>
          <button class="w-8 h-8 flex items-center justify-center rounded-xl bg-[#FF7B89] text-white font-bold shadow-sm shadow-pink-200">1</button>
          <button class="w-8 h-8 flex items-center justify-center rounded-xl border border-gray-200 text-gray-600 hover:bg-gray-50 hover:border-gray-300 transition-all">2</button>
          <button class="w-8 h-8 flex items-center justify-center rounded-xl border border-gray-200 text-gray-600 hover:bg-gray-50 hover:border-gray-300 transition-all">3</button>
          <button class="w-8 h-8 flex items-center justify-center rounded-xl border border-gray-200 text-gray-500 hover:bg-gray-50 hover:border-gray-300 transition-all">&gt;</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const auditLogs = ref([
  {
    id: 1,
    time: '23/06/2026 08:45:12',
    branch: 'Chi nhánh 1',
    user: 'admin_nguu_cat',
    action: 'UPDATE',
    entityType: 'KPI_Target',
    entityId: 'KPI-2026-06',
    payload: '{"revenue": 500000000, "guests": 1500}'
  },
  {
    id: 2,
    time: '23/06/2026 08:30:05',
    branch: 'Chi nhánh 2',
    user: 'manager_cn2',
    action: 'CREATE',
    entityType: 'Order',
    entityId: 'ORD-84920',
    payload: '{"table": "T05", "total": 1250000, "items": [...] }'
  },
  {
    id: 3,
    time: '23/06/2026 08:15:22',
    branch: 'Hệ thống',
    user: 'admin_nguu_cat',
    action: 'LOGIN',
    entityType: 'Session',
    entityId: 'SES-9912',
    payload: '{"ip": "192.168.1.45", "device": "Chrome/Windows"}'
  },
  {
    id: 4,
    time: '23/06/2026 07:50:11',
    branch: 'Chi nhánh 1',
    user: 'staff_thu_ngan',
    action: 'DELETE',
    entityType: 'OrderItem',
    entityId: 'ITEM-4821',
    payload: '{"reason": "Khách đổi ý", "item": "Mỳ Ý Bò Băm"}'
  },
  {
    id: 5,
    time: '23/06/2026 07:45:00',
    branch: 'Chi nhánh 1',
    user: 'manager_cn1',
    action: 'UPDATE',
    entityType: 'Table',
    entityId: 'TBL-V01',
    payload: '{"status": "RESERVED", "customer_name": "Anh Tuấn"}'
  }
]);
</script>
