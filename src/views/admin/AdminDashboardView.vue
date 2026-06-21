<template>
  <div class="space-y-6 max-w-7xl mx-auto">
    <!-- Header -->
    <div>
      <h1 class="text-2xl font-bold text-gray-900 tracking-tight">Tổng Quan Hệ Thống</h1>
      <p class="text-sm text-gray-500 mt-1">Trạng thái hoạt động của hệ thống Ngưu Cát</p>
    </div>

    <!-- Quick Stats -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <div class="bg-white rounded-2xl border border-gray-200 p-5 shadow-sm">
        <div class="flex items-center gap-3 mb-2">
          <div class="w-8 h-8 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          </div>
          <span class="text-sm font-bold text-gray-500">Tài Khoản Active</span>
        </div>
        <div class="text-3xl font-black text-gray-900">42</div>
      </div>

      <div class="bg-white rounded-2xl border border-gray-200 p-5 shadow-sm">
        <div class="flex items-center gap-3 mb-2">
          <div class="w-8 h-8 rounded-full bg-green-100 text-green-600 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="3" rx="2"/><path d="M3 9a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2"/><path d="M3 11h3c.8 0 1.6.3 2.1.9l1.1.9c.6.6 1.3.9 2.1.9h3.4c.8 0 1.6-.3 2.1-.9l1.1-.9c.6-.6 1.3-.9 2.1-.9h3"/></svg>
          </div>
          <span class="text-sm font-bold text-gray-500">Gói Thực Đơn</span>
        </div>
        <div class="text-3xl font-black text-gray-900">12</div>
      </div>

      <div class="bg-white rounded-2xl border border-gray-200 p-5 shadow-sm">
        <div class="flex items-center gap-3 mb-2">
          <div class="w-8 h-8 rounded-full bg-orange-100 text-orange-600 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><line x1="3" x2="21" y1="9" y2="9"/><line x1="9" x2="9" y1="21" y2="9"/></svg>
          </div>
          <span class="text-sm font-bold text-gray-500">Bàn Thiết Lập</span>
        </div>
        <div class="text-3xl font-black text-gray-900">28</div>
      </div>

      <div class="bg-white rounded-2xl border border-gray-200 p-5 shadow-sm">
        <div class="flex items-center gap-3 mb-2">
          <div class="w-8 h-8 rounded-full bg-purple-100 text-purple-600 flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>
          </div>
          <span class="text-sm font-bold text-gray-500">Trạng Thái API</span>
        </div>
        <div class="text-xl font-black text-green-600 mt-2">Bình thường</div>
      </div>
    </div>

    <!-- Recent Audit Logs -->
    <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
      <div class="p-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
        <h3 class="font-bold text-gray-900">Nhật Ký Hoạt Động Mới Nhất</h3>
        <RouterLink to="/admin/audit" class="text-sm font-bold text-blue-600 hover:text-blue-800">Xem tất cả</RouterLink>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-left text-sm">
          <thead class="bg-gray-50 text-gray-500 font-semibold border-b">
            <tr>
              <th class="px-5 py-3">Thời gian</th>
              <th class="px-5 py-3">Người dùng</th>
              <th class="px-5 py-3">Hành động</th>
              <th class="px-5 py-3">IP</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr class="hover:bg-gray-50">
              <td class="px-5 py-3 text-gray-500">20/06/2026 10:15</td>
              <td class="px-5 py-3 font-medium text-gray-900">Admin_Q1</td>
              <td class="px-5 py-3">Cập nhật giá Menu Biz 1200k</td>
              <td class="px-5 py-3 text-gray-400">118.69.123.45</td>
            </tr>
            <tr class="hover:bg-gray-50">
              <td class="px-5 py-3 text-gray-500">20/06/2026 09:30</td>
              <td class="px-5 py-3 font-medium text-gray-900">System</td>
              <td class="px-5 py-3 text-blue-600 font-medium">Backup dữ liệu định kỳ</td>
              <td class="px-5 py-3 text-gray-400">localhost</td>
            </tr>
            <tr class="hover:bg-gray-50">
              <td class="px-5 py-3 text-gray-500">19/06/2026 23:45</td>
              <td class="px-5 py-3 font-medium text-gray-900">Manager_NV</td>
              <td class="px-5 py-3">Kết ca và xuất báo cáo ngày</td>
              <td class="px-5 py-3 text-gray-400">118.69.123.45</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
