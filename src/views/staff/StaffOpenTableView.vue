<template>
  <div class="p-4 flex flex-col min-h-full">
    <div class="mb-6 flex items-center gap-3">
      <RouterLink to="/staff/floor-plan" class="w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center text-gray-600">
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg>
      </RouterLink>
      <div>
        <h2 class="text-xl font-bold text-gray-900">Mở bàn: T1-B1</h2>
        <p class="text-xs text-gray-500">Scan QR & Profile Khách</p>
      </div>
    </div>

    <!-- Step 1: Pairing -->
    <div class="bg-white rounded-2xl p-4 shadow-sm border border-gray-200 mb-4">
      <div class="text-sm font-bold text-gray-800 mb-3 flex items-center gap-2">
        <div class="w-5 h-5 rounded-full bg-red-100 text-red-600 flex items-center justify-center text-xs">1</div>
        Quét QR trên Tablet
      </div>
      <div class="flex gap-2">
        <input type="text" placeholder="Nhập mã hoặc quét..." class="flex-1 bg-gray-50 border border-gray-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:border-red-500" value="T1-A4" />
        <button class="bg-gray-800 text-white p-2 rounded-xl">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7V5a2 2 0 0 1 2-2h2"/><path d="M17 3h2a2 2 0 0 1 2 2v2"/><path d="M21 17v2a2 2 0 0 1-2 2h-2"/><path d="M7 21H5a2 2 0 0 1-2-2v-2"/><rect width="5" height="5" x="7" y="7" rx="1"/><rect width="5" height="5" x="12" y="12" rx="1"/></svg>
        </button>
      </div>
    </div>

    <!-- Step 2: Profile -->
    <div class="bg-white rounded-2xl p-4 shadow-sm border border-gray-200 mb-4">
      <div class="text-sm font-bold text-gray-800 mb-4 flex items-center gap-2">
        <div class="w-5 h-5 rounded-full bg-red-100 text-red-600 flex items-center justify-center text-xs">2</div>
        Thông tin khách hàng
      </div>
      
      <div class="space-y-4">
        <label class="flex items-center gap-3 p-3 border border-red-200 bg-red-50 rounded-xl cursor-pointer">
          <input type="checkbox" class="w-5 h-5 text-red-600 accent-red-600" />
          <span class="text-sm font-bold text-red-800">Dự đoán là Khách Quen (Repeater)</span>
        </label>

        <div class="grid grid-cols-2 gap-3">
          <div>
            <span class="text-xs text-gray-500 font-medium block mb-1">Số lượng Nam</span>
            <div class="flex items-center bg-gray-50 border border-gray-200 rounded-xl overflow-hidden">
              <button class="w-10 h-10 flex items-center justify-center text-gray-500 border-r">-</button>
              <input type="text" class="flex-1 w-full text-center bg-transparent font-bold text-sm" value="2" />
              <button class="w-10 h-10 flex items-center justify-center text-gray-500 border-l">+</button>
            </div>
          </div>
          <div>
            <span class="text-xs text-gray-500 font-medium block mb-1">Số lượng Nữ</span>
            <div class="flex items-center bg-gray-50 border border-gray-200 rounded-xl overflow-hidden">
              <button class="w-10 h-10 flex items-center justify-center text-gray-500 border-r">-</button>
              <input type="text" class="flex-1 w-full text-center bg-transparent font-bold text-sm" value="1" />
              <button class="w-10 h-10 flex items-center justify-center text-gray-500 border-l">+</button>
            </div>
          </div>
          <div>
            <span class="text-xs text-gray-500 font-medium block mb-1">Trẻ em</span>
            <div class="flex items-center bg-gray-50 border border-gray-200 rounded-xl overflow-hidden">
              <button class="w-10 h-10 flex items-center justify-center text-gray-500 border-r">-</button>
              <input type="text" class="flex-1 w-full text-center bg-transparent font-bold text-sm" value="0" />
              <button class="w-10 h-10 flex items-center justify-center text-gray-500 border-l">+</button>
            </div>
          </div>
          <div>
            <span class="text-xs text-gray-500 font-medium block mb-1">Độ tuổi chung</span>
            <select class="w-full h-10 bg-gray-50 border border-gray-200 rounded-xl px-2 text-sm font-bold text-gray-700">
              <option>20-30</option>
              <option>30-40</option>
              <option>40-50</option>
              <option>50+</option>
            </select>
          </div>
        </div>
      </div>
    </div>

    <!-- Step 3: Course -->
    <div class="bg-white rounded-2xl p-4 shadow-sm border border-gray-200 mb-6">
      <div class="text-sm font-bold text-gray-800 mb-4 flex items-center gap-2">
        <div class="w-5 h-5 rounded-full bg-red-100 text-red-600 flex items-center justify-center text-xs">3</div>
        Chọn Gói (Course Selection)
      </div>

      <div class="space-y-3">
        <div>
          <span class="text-xs text-gray-500 font-medium block mb-1">Gói Đồ Ăn</span>
          <select class="w-full h-12 bg-gray-50 border border-gray-200 rounded-xl px-3 text-sm font-bold text-gray-900">
            <option>Buffet Premium 1380k</option>
            <option>Buffet Standard 1150k</option>
            <option>Set Biz 1200k</option>
          </select>
        </div>

        <div>
          <span class="text-xs text-gray-500 font-medium block mb-1">Gói Đồ Uống</span>
          <select class="w-full h-12 bg-gray-50 border border-gray-200 rounded-xl px-3 text-sm font-bold text-gray-900">
            <option>Softdrink Free (A)</option>
            <option>Alcohol Free (B)</option>
            <option>Alcohol Free Premium (C)</option>
            <option>None (D)</option>
          </select>
        </div>

        <div class="pt-2">
          <span class="text-xs text-gray-500 font-medium block mb-2">Quyền kiểm soát (Tablet Control)</span>
          <div class="grid grid-cols-2 gap-2">
            <button class="bg-red-50 border-2 border-red-500 text-red-700 font-bold py-2 rounded-xl text-xs flex flex-col items-center gap-1">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
              Khóa Course (1 Chiều)
            </button>
            <button class="bg-gray-50 border border-gray-200 text-gray-600 font-bold py-2 rounded-xl text-xs flex flex-col items-center gap-1">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 9.9-1"/></svg>
              Luồng Tự Do (Buffet)
            </button>
          </div>
        </div>
      </div>
    </div>

    <button class="mt-auto w-full bg-red-600 hover:bg-red-700 text-white font-bold py-4 rounded-2xl shadow-lg transition-colors text-lg">
      Mở Bàn & Kích Hoạt Tablet
    </button>
  </div>
</template>
