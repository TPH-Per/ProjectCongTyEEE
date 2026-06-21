<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-start justify-between">
      <div>
        <h1 class="text-2xl font-black text-[hsl(var(--foreground))] tracking-tight">Tổng Kết Ca</h1>
        <p class="text-sm text-[hsl(var(--muted-foreground))] mt-1">シフト終了レポート — Đóng ca & Xuất báo cáo ngày 20/06/2026</p>
      </div>
      <div class="flex gap-2">
        <button class="kawaii-btn-ghost px-4 py-2 text-sm font-bold flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/></svg>
          Xuất CSV
        </button>
        <button class="kawaii-btn-ghost px-4 py-2 text-sm font-bold flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/><polyline points="14 2 14 8 20 8"/></svg>
          Xuất Excel
        </button>
        <button class="kawaii-btn-primary px-5 py-2 text-sm font-bold flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
          Xác Nhận Đóng Ca
        </button>
      </div>
    </div>

    <!-- Revenue by Type -->
    <div class="kawaii-card p-6">
      <h3 class="font-bold text-base text-[hsl(var(--foreground))] mb-5">Doanh Thu Theo Loại Hình (本日売上分類)</h3>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <div class="rounded-2xl border-2 border-red-200 bg-red-50 p-4 text-center">
          <div class="text-2xl mb-2">🍖</div>
          <div class="text-xs font-bold text-red-400 uppercase tracking-wide mb-1">Bữa Tối (Dinner)</div>
          <div class="text-2xl font-black text-red-700">7,200,000</div>
          <div class="text-xs text-red-400 mt-1">58% • 148 khách</div>
        </div>
        <div class="rounded-2xl border-2 border-orange-200 bg-orange-50 p-4 text-center">
          <div class="text-2xl mb-2">🍱</div>
          <div class="text-xs font-bold text-orange-400 uppercase tracking-wide mb-1">Bữa Trưa (Lunch)</div>
          <div class="text-2xl font-black text-orange-700">3,400,000</div>
          <div class="text-xs text-orange-400 mt-1">27.4% • 72 khách</div>
        </div>
        <div class="rounded-2xl border-2 border-purple-200 bg-purple-50 p-4 text-center">
          <div class="text-2xl mb-2">🍶</div>
          <div class="text-xs font-bold text-purple-400 uppercase tracking-wide mb-1">Rượu/Wine</div>
          <div class="text-2xl font-black text-purple-700">1,100,000</div>
          <div class="text-xs text-purple-400 mt-1">8.9% • kèm bữa</div>
        </div>
        <div class="rounded-2xl border-2 border-blue-200 bg-blue-50 p-4 text-center">
          <div class="text-2xl mb-2">🛵</div>
          <div class="text-xs font-bold text-blue-400 uppercase tracking-wide mb-1">Giao Hàng (Delivery)</div>
          <div class="text-2xl font-black text-blue-700">700,000</div>
          <div class="text-xs text-blue-400 mt-1">5.6% • 28 đơn</div>
        </div>
      </div>

      <div class="bg-[hsl(var(--muted))] rounded-xl p-4 flex items-center justify-between">
        <div class="font-black text-lg text-[hsl(var(--foreground))]">Tổng Doanh Thu Ngày</div>
        <div class="text-3xl font-black text-[hsl(var(--primary))]">12,400,000đ</div>
      </div>
    </div>

    <!-- Session Summary Table -->
    <div class="kawaii-card overflow-hidden">
      <div class="kawaii-card-header">
        <span class="font-bold text-sm">Lịch Sử Thanh Toán Trong Ca</span>
        <span class="kawaii-pill bg-[hsl(var(--primary))]/10 text-[hsl(var(--primary))]">12 bàn</span>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-[hsl(var(--border))]">
              <th class="text-left py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">Bàn</th>
              <th class="text-left py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">Loại</th>
              <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">Khách</th>
              <th class="text-left py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">Gói</th>
              <th class="text-left py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">Kênh</th>
              <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">Doanh Thu</th>
              <th class="text-left py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">TG Thanh Toán</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-[hsl(var(--border))]">
            <tr v-for="session in sessions" :key="session.table" class="hover:bg-[hsl(var(--muted))]/50">
              <td class="py-2.5 px-4 font-bold text-[hsl(var(--foreground))]">{{ session.table }}</td>
              <td class="py-2.5 px-4">
                <span :class="typeClass(session.type)" class="kawaii-pill">{{ session.type }}</span>
              </td>
              <td class="py-2.5 px-4 text-right text-gray-600">{{ session.guests }}</td>
              <td class="py-2.5 px-4 text-gray-600 text-xs">{{ session.course }}</td>
              <td class="py-2.5 px-4 text-xs text-gray-500">{{ session.channel }}</td>
              <td class="py-2.5 px-4 text-right font-bold text-[hsl(var(--foreground))]">{{ session.revenue.toLocaleString() }}đ</td>
              <td class="py-2.5 px-4 text-gray-500 text-xs">{{ session.time }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Staff Notes -->
    <div class="kawaii-card p-6">
      <h3 class="font-bold text-base text-[hsl(var(--foreground))] mb-3">Ghi Chú Ca (本日特記事項)</h3>
      <textarea class="kawaii-input w-full py-3 text-sm h-24 resize-none" placeholder="Ghi chú bất thường trong ca, vấn đề cần bàn giao..."></textarea>
      <div class="flex justify-end mt-3">
        <button class="kawaii-btn-primary px-5 py-2 text-sm font-bold">Lưu Ghi Chú</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const sessions = [
  { table: 'T1-A4', type: 'Dinner', guests: 4, course: 'Premium Buffet 1380k', channel: 'Zalo OA', revenue: 5520000, time: '21:35' },
  { table: 'T2-B2', type: 'Dinner', guests: 2, course: 'Set Biz 1200k', channel: 'Google Map', revenue: 2400000, time: '21:10' },
  { table: 'T1-C1', type: 'Lunch', guests: 3, course: 'Lunch 380k', channel: 'Walk-in', revenue: 1140000, time: '13:20' },
  { table: 'T3-A1', type: 'Dinner', guests: 6, course: 'Buffet 1150k', channel: 'Facebook', revenue: 6900000, time: '20:45' },
  { table: 'T2-A3', type: 'Lunch', guests: 2, course: 'Lunch 380k', channel: 'Người quen', revenue: 760000, time: '12:55' },
]

function typeClass(type: string) {
  if (type === 'Dinner') return 'bg-red-100 text-red-700'
  if (type === 'Lunch') return 'bg-orange-100 text-orange-700'
  if (type === 'Wine') return 'bg-purple-100 text-purple-700'
  return 'bg-blue-100 text-blue-700'
}
</script>
