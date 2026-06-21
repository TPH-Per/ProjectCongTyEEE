<template>
  <div class="space-y-6 max-w-7xl mx-auto">
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 tracking-tight">Quản Lý Tài Khoản</h1>
        <p class="text-sm text-gray-500 mt-1">Thiết lập tài khoản và phân quyền nhân viên</p>
      </div>
      <button class="bg-gray-900 hover:bg-black text-white px-5 py-2.5 rounded-xl font-bold transition-colors flex items-center gap-2 text-sm shadow-md">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" x2="12" y1="5" y2="19"/><line x1="5" x2="19" y1="12" y2="12"/></svg>
        Tạo Tài Khoản
      </button>
    </div>

    <!-- Filters -->
    <div class="bg-white rounded-2xl border border-gray-200 p-4 shadow-sm flex items-center gap-4">
      <div class="flex-1 relative">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
        <input type="text" placeholder="Tìm tên, mã nhân viên..." class="w-full bg-gray-50 border border-gray-200 rounded-xl pl-9 pr-4 py-2.5 text-sm focus:outline-none focus:border-gray-400 font-medium" />
      </div>
      <select class="bg-gray-50 border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-gray-400 font-medium">
        <option value="all">Tất cả vai trò</option>
        <option value="admin">System Admin</option>
        <option value="manager">Manager</option>
        <option value="reception">Thu Ngân</option>
        <option value="staff">Phục Vụ</option>
      </select>
    </div>

    <!-- Accounts Table -->
    <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
      <table class="w-full text-left text-sm">
        <thead class="bg-gray-50 text-gray-500 font-semibold border-b">
          <tr>
            <th class="px-5 py-3">ID</th>
            <th class="px-5 py-3">Họ Tên</th>
            <th class="px-5 py-3">Vai Trò (Role)</th>
            <th class="px-5 py-3">Trạng Thái</th>
            <th class="px-5 py-3">Hành động</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          <tr class="hover:bg-gray-50">
            <td class="px-5 py-3 font-bold text-gray-900">AD01</td>
            <td class="px-5 py-3 font-medium text-gray-900">Trần Quản Trị</td>
            <td class="px-5 py-3">
              <span class="px-2.5 py-1 rounded-md text-xs font-bold bg-gray-900 text-white">Admin</span>
            </td>
            <td class="px-5 py-3">
              <span class="flex items-center gap-1.5 text-green-600 font-medium text-xs">
                <span class="w-2 h-2 rounded-full bg-green-500"></span> Đang hoạt động
              </span>
            </td>
            <td class="px-5 py-3">
              <button class="text-blue-600 hover:text-blue-800 font-medium">Sửa</button>
            </td>
          </tr>
          <tr class="hover:bg-gray-50">
            <td class="px-5 py-3 font-bold text-gray-900">QL01</td>
            <td class="px-5 py-3 font-medium text-gray-900">Lê Quản Lý</td>
            <td class="px-5 py-3">
              <span class="px-2.5 py-1 rounded-md text-xs font-bold bg-blue-100 text-blue-700 border border-blue-200">Manager</span>
            </td>
            <td class="px-5 py-3">
              <span class="flex items-center gap-1.5 text-green-600 font-medium text-xs">
                <span class="w-2 h-2 rounded-full bg-green-500"></span> Đang hoạt động
              </span>
            </td>
            <td class="px-5 py-3">
              <button class="text-blue-600 hover:text-blue-800 font-medium">Sửa</button>
            </td>
          </tr>
          <tr class="hover:bg-gray-50">
            <td class="px-5 py-3 font-bold text-gray-900">RC01</td>
            <td class="px-5 py-3 font-medium text-gray-900">Nguyễn Thu Ngân</td>
            <td class="px-5 py-3">
              <span class="px-2.5 py-1 rounded-md text-xs font-bold bg-purple-100 text-purple-700 border border-purple-200">Thu Ngân</span>
            </td>
            <td class="px-5 py-3">
              <span class="flex items-center gap-1.5 text-green-600 font-medium text-xs">
                <span class="w-2 h-2 rounded-full bg-green-500"></span> Đang hoạt động
              </span>
            </td>
            <td class="px-5 py-3">
              <button class="text-blue-600 hover:text-blue-800 font-medium">Sửa</button>
            </td>
          </tr>
          <tr class="hover:bg-gray-50">
            <td class="px-5 py-3 font-bold text-gray-900">NV01</td>
            <td class="px-5 py-3 font-medium text-gray-900">Nguyễn Văn A</td>
            <td class="px-5 py-3">
              <span class="px-2.5 py-1 rounded-md text-xs font-bold bg-orange-100 text-orange-700 border border-orange-200">Phục Vụ</span>
            </td>
            <td class="px-5 py-3">
              <span class="flex items-center gap-1.5 text-green-600 font-medium text-xs">
                <span class="w-2 h-2 rounded-full bg-green-500"></span> Đang hoạt động
              </span>
            </td>
            <td class="px-5 py-3">
              <button class="text-blue-600 hover:text-blue-800 font-medium">Sửa</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
