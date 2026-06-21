<template>
  <div>
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Tổng quan ca làm việc</h2>
        <p class="text-sm text-gray-500">20 Tháng 6, 2026 - Ca Sáng</p>
      </div>
      <div class="flex gap-3">
        <div class="bg-white border px-4 py-2 rounded-xl text-center">
          <div class="text-[10px] font-bold text-gray-400 uppercase tracking-wide">Bàn Đang Dùng</div>
          <div class="text-xl font-black text-gray-900">12</div>
        </div>
        <div class="bg-white border px-4 py-2 rounded-xl text-center">
          <div class="text-[10px] font-bold text-gray-400 uppercase tracking-wide">Chờ Thanh Toán</div>
          <div class="text-xl font-black text-red-600">2</div>
        </div>
      </div>
    </div>

    <!-- Alerts Section -->
    <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider mb-4">Cần Xử Lý Ngay</h3>
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
      
      <!-- Checkout Alert -->
      <div class="bg-red-50 border-2 border-red-500 rounded-2xl p-5 shadow-sm relative overflow-hidden">
        <div class="absolute top-0 right-0 w-16 h-16 bg-red-100 rounded-bl-full flex items-center justify-center">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-red-500 animate-pulse translate-x-2 -translate-y-2"><path d="M22 17a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9.5C2 7 4 5 6.5 5H18c2.2 0 4 1.8 4 4v8Z"/><polyline points="15,9 18,9 18,11"/><path d="M6.5 5C9 5 11 7 11 9.5V17a2 2 0 0 1-2 2v0"/><line x1="6" x2="6" y1="10" y2="10"/></svg>
        </div>
        <div class="flex items-center gap-3 mb-3">
          <div class="w-3 h-3 rounded-full bg-red-500 animate-pulse"></div>
          <span class="font-bold text-red-700">Yêu Cầu Thanh Toán</span>
        </div>
        <div class="text-3xl font-black text-gray-900 mb-1">Bàn T2-A1</div>
        <div class="text-sm text-gray-600 mb-6">4 Khách • Set Biz 1200k</div>
        <RouterLink to="/reception/checkout/T2-A1" class="block w-full bg-red-600 hover:bg-red-700 text-white text-center font-bold py-3 rounded-xl transition-colors">
          Tiến Hành Thanh Toán
        </RouterLink>
      </div>

      <!-- Checkout Alert 2 -->
      <div class="bg-red-50 border-2 border-red-500 rounded-2xl p-5 shadow-sm relative overflow-hidden">
        <div class="absolute top-0 right-0 w-16 h-16 bg-red-100 rounded-bl-full flex items-center justify-center">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-red-500 animate-pulse translate-x-2 -translate-y-2"><path d="M22 17a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9.5C2 7 4 5 6.5 5H18c2.2 0 4 1.8 4 4v8Z"/><polyline points="15,9 18,9 18,11"/><path d="M6.5 5C9 5 11 7 11 9.5V17a2 2 0 0 1-2 2v0"/><line x1="6" x2="6" y1="10" y2="10"/></svg>
        </div>
        <div class="flex items-center gap-3 mb-3">
          <div class="w-3 h-3 rounded-full bg-red-500 animate-pulse"></div>
          <span class="font-bold text-red-700">Yêu Cầu Thanh Toán</span>
        </div>
        <div class="text-3xl font-black text-gray-900 mb-1">Bàn T1-A4</div>
        <div class="text-sm text-gray-600 mb-6">4 Khách • Premium Buffet</div>
        <RouterLink to="/reception/checkout/T1-A4" class="block w-full bg-red-600 hover:bg-red-700 text-white text-center font-bold py-3 rounded-xl transition-colors">
          Tiến Hành Thanh Toán
        </RouterLink>
      </div>

    </div>

    <h3 class="text-sm font-bold text-gray-500 uppercase tracking-wider mb-4">Danh Sách Bàn Đang Phục Vụ</h3>
    <div class="bg-white border rounded-2xl overflow-hidden shadow-sm">
      <table class="w-full text-left border-collapse">
        <thead>
          <tr class="bg-gray-50 border-b">
            <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">Mã Bàn</th>
            <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">Gói Dịch Vụ</th>
            <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">Khách</th>
            <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">Thời Gian</th>
            <th class="py-3 px-4 text-xs font-bold text-gray-500 uppercase">Trạng Thái</th>
          </tr>
        </thead>
        <tbody class="text-sm divide-y">
          <tr class="hover:bg-gray-50 transition-colors">
            <td class="py-3 px-4 font-bold text-gray-900">T1-B3</td>
            <td class="py-3 px-4 text-gray-600">Lunch 380k + Drink D</td>
            <td class="py-3 px-4 text-gray-600">2</td>
            <td class="py-3 px-4 text-gray-600">45 phút</td>
            <td class="py-3 px-4"><span class="bg-green-100 text-green-700 px-2 py-1 rounded text-xs font-bold">Đang dùng bữa</span></td>
          </tr>
          <tr class="hover:bg-gray-50 transition-colors">
            <td class="py-3 px-4 font-bold text-gray-900">T3-C2</td>
            <td class="py-3 px-4 text-gray-600">Buffet 680k + Drink B</td>
            <td class="py-3 px-4 text-gray-600">6</td>
            <td class="py-3 px-4 text-gray-600">1h 20m</td>
            <td class="py-3 px-4"><span class="bg-green-100 text-green-700 px-2 py-1 rounded text-xs font-bold">Đang dùng bữa</span></td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
