<template>
  <div class="space-y-6 max-w-7xl mx-auto">
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 tracking-tight">Thực Đơn & Gói Menu</h1>
        <p class="text-sm text-gray-500 mt-1">Quản lý các món ăn, gói Buffet/Set và Drink Packages</p>
      </div>
      <div class="flex gap-3">
        <button class="bg-white border border-gray-200 hover:bg-gray-50 text-gray-900 px-5 py-2.5 rounded-xl font-bold transition-colors text-sm shadow-sm">
          Thêm Món Mới
        </button>
        <button class="bg-gray-900 hover:bg-black text-white px-5 py-2.5 rounded-xl font-bold transition-colors text-sm shadow-md">
          Thêm Gói Menu
        </button>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Left: Packages -->
      <div class="lg:col-span-1 space-y-6">
        <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
          <div class="p-4 border-b border-gray-100 bg-gray-50">
            <h3 class="font-bold text-gray-900">Gói Buffet / Set Menu</h3>
          </div>
          <div class="p-4 space-y-3">
            <div class="border border-red-200 bg-red-50 p-3 rounded-xl cursor-pointer hover:border-red-300">
              <div class="flex justify-between items-center mb-1">
                <span class="font-bold text-red-700">Set Biz 1200k</span>
                <span class="text-xs bg-white px-2 py-0.5 rounded-md border border-red-100 font-bold text-red-600">53 Món</span>
              </div>
              <div class="text-sm font-semibold text-gray-900">1,200,000 đ</div>
            </div>
            
            <div class="border border-gray-200 p-3 rounded-xl cursor-pointer hover:border-gray-300">
              <div class="flex justify-between items-center mb-1">
                <span class="font-bold text-gray-700">Buffet Wagyu 1380k</span>
                <span class="text-xs bg-gray-100 px-2 py-0.5 rounded-md border font-bold text-gray-600">110 Món</span>
              </div>
              <div class="text-sm font-semibold text-gray-900">1,380,000 đ</div>
            </div>

            <div class="border border-gray-200 p-3 rounded-xl cursor-pointer hover:border-gray-300">
              <div class="flex justify-between items-center mb-1">
                <span class="font-bold text-gray-700">Buffet Standard 1150k</span>
                <span class="text-xs bg-gray-100 px-2 py-0.5 rounded-md border font-bold text-gray-600">104 Món</span>
              </div>
              <div class="text-sm font-semibold text-gray-900">1,150,000 đ</div>
            </div>
          </div>
        </div>

        <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
          <div class="p-4 border-b border-gray-100 bg-gray-50">
            <h3 class="font-bold text-gray-900">Gói Đồ Uống (Drink Packages)</h3>
          </div>
          <div class="p-4 space-y-3">
            <div class="flex justify-between items-center border-b pb-2">
              <span class="font-bold text-gray-700">Drink A (Free Flow)</span>
              <span class="text-sm font-semibold">250,000 đ</span>
            </div>
            <div class="flex justify-between items-center border-b pb-2">
              <span class="font-bold text-gray-700">Drink B (Bia & Rượu)</span>
              <span class="text-sm font-semibold">350,000 đ</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="font-bold text-gray-700">Không có gói (Gọi lẻ)</span>
              <span class="text-sm font-semibold text-gray-400">0 đ</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Right: Items in Package -->
      <div class="lg:col-span-2">
        <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden flex flex-col h-full">
          <div class="p-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
            <div>
              <h3 class="font-bold text-gray-900 text-lg">Danh Sách Món: Set Biz 1200k</h3>
              <p class="text-xs text-gray-500 mt-1">Các món hiển thị trên Tablet cho khách chọn</p>
            </div>
            <button class="text-blue-600 text-sm font-bold hover:text-blue-800 flex items-center gap-1">
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/><path d="m15 5 4 4"/></svg>
              Sửa Danh Sách
            </button>
          </div>
          <div class="p-0 overflow-x-auto">
            <table class="w-full text-left text-sm">
              <thead class="bg-white text-gray-500 font-semibold border-b">
                <tr>
                  <th class="px-5 py-3 w-16">Hiển thị</th>
                  <th class="px-5 py-3">Danh Mục</th>
                  <th class="px-5 py-3">Tên Món</th>
                  <th class="px-5 py-3">Giá Lẻ</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr class="hover:bg-gray-50">
                  <td class="px-5 py-3">
                    <input type="checkbox" checked class="rounded text-red-600 focus:ring-red-500 w-4 h-4 cursor-pointer" />
                  </td>
                  <td class="px-5 py-3 text-gray-500">Thịt Bò</td>
                  <td class="px-5 py-3 font-bold text-gray-900">Thăn Ngoại Wagyu A5</td>
                  <td class="px-5 py-3 text-gray-600">500,000 đ</td>
                </tr>
                <tr class="hover:bg-gray-50">
                  <td class="px-5 py-3">
                    <input type="checkbox" checked class="rounded text-red-600 focus:ring-red-500 w-4 h-4 cursor-pointer" />
                  </td>
                  <td class="px-5 py-3 text-gray-500">Thịt Bò</td>
                  <td class="px-5 py-3 font-bold text-gray-900">Lưỡi Bò Thượng Hạng</td>
                  <td class="px-5 py-3 text-gray-600">400,000 đ</td>
                </tr>
                <tr class="hover:bg-gray-50">
                  <td class="px-5 py-3">
                    <input type="checkbox" class="rounded text-red-600 focus:ring-red-500 w-4 h-4 cursor-pointer" />
                  </td>
                  <td class="px-5 py-3 text-gray-400">Thịt Bò</td>
                  <td class="px-5 py-3 font-medium text-gray-400 line-through">Lõi Vai Bò Mỹ</td>
                  <td class="px-5 py-3 text-gray-400">300,000 đ</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
