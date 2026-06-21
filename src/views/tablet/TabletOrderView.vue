<template>
  <div class="flex-1 flex flex-col h-full overflow-hidden bg-[#111111]">
    <!-- Header -->
    <header class="h-20 bg-[#1e1e1e] border-b border-gray-800 flex items-center justify-between px-8 shrink-0">
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 bg-red-600 rounded-xl flex items-center justify-center text-white font-bold text-xl">
          🐂
        </div>
        <div>
          <h2 class="text-xl font-bold text-white">Bàn T1-A4</h2>
          <p class="text-sm text-gray-400">Premium Buffet 1380k + Drink A</p>
        </div>
      </div>
      
      <div class="flex items-center gap-6">
        <div class="bg-gray-800 rounded-full px-4 py-2 flex items-center gap-2">
          <span class="text-gray-400 font-medium">Giới hạn gọi món:</span>
          <span class="text-white font-bold"><span class="text-red-500">3</span> / 10 món</span>
        </div>
        <button class="bg-red-600 hover:bg-red-700 text-white font-bold py-3 px-8 rounded-full text-lg shadow-[0_0_15px_rgba(220,38,38,0.5)] transition-all">
          Gửi Bếp
        </button>
      </div>
    </header>

    <!-- Main Content -->
    <div class="flex-1 flex overflow-hidden">
      <!-- Categories Sidebar -->
      <aside class="w-64 bg-[#1a1a1a] border-r border-gray-800 overflow-y-auto">
        <div class="p-4 space-y-2">
          <div class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-4 px-4">Menu</div>
          
          <button class="w-full text-left px-6 py-4 rounded-xl bg-red-600/20 text-red-500 font-bold border border-red-600/30">
            🥩 Thịt Bò Wagyu
          </button>
          <button class="w-full text-left px-6 py-4 rounded-xl text-gray-400 hover:bg-gray-800 hover:text-white font-medium transition-colors">
            🦐 Hải Sản
          </button>
          <button class="w-full text-left px-6 py-4 rounded-xl text-gray-400 hover:bg-gray-800 hover:text-white font-medium transition-colors">
            🥗 Rau Củ & Nấm
          </button>
          <button class="w-full text-left px-6 py-4 rounded-xl text-gray-400 hover:bg-gray-800 hover:text-white font-medium transition-colors">
            🍚 Cơm & Mì
          </button>
          <!-- Locked Category Example -->
          <div class="relative group mt-8">
            <button class="w-full text-left px-6 py-4 rounded-xl text-gray-600 font-medium cursor-not-allowed flex justify-between items-center bg-gray-900">
              <span>🍺 Đồ Uống Cồn</span>
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
            </button>
            <!-- Tooltip -->
            <div class="absolute bottom-full left-0 mb-2 hidden group-hover:block w-full text-center">
              <div class="bg-red-900 text-red-200 text-xs py-1 px-2 rounded">Khóa bởi nhân viên (Gói Drink A)</div>
            </div>
          </div>
        </div>
      </aside>

      <!-- Items Grid -->
      <main class="flex-1 overflow-y-auto p-8">
        <!-- Notice if flow is locked -->
        <div class="mb-6 bg-blue-900/30 border border-blue-800 rounded-xl p-4 flex items-start gap-3">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-blue-400 mt-0.5"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/></svg>
          <div>
            <h4 class="text-blue-400 font-bold text-sm">Luồng Gọi Món 1 Chiều</h4>
            <p class="text-gray-400 text-sm mt-1">Quý khách vui lòng chọn các món trong danh mục hiện tại trước khi tiếp tục. Không thể quay lại trang trước.</p>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
          <!-- Item Card -->
          <div class="bg-[#1e1e1e] rounded-2xl border border-gray-800 overflow-hidden flex flex-col group hover:border-gray-600 transition-colors">
            <div class="h-48 bg-gray-800 relative">
              <img src="https://images.unsplash.com/photo-1603048297172-c92544798d5e?auto=format&fit=crop&q=80" alt="Wagyu" class="w-full h-full object-cover" />
              <div class="absolute top-3 right-3 bg-red-600 text-white text-xs font-bold px-2 py-1 rounded">Best Seller</div>
            </div>
            <div class="p-5 flex-1 flex flex-col">
              <h3 class="text-lg font-bold text-white mb-1">Thăn Ngoại Bò Wagyu A5</h3>
              <p class="text-sm text-gray-400 mb-4 flex-1">Premium Wagyu Striploin</p>
              
              <div class="flex items-center justify-between mt-auto">
                <span class="text-red-500 font-bold">0đ <span class="text-xs text-gray-500">(Trong gói)</span></span>
                <div class="flex items-center gap-3 bg-black rounded-full p-1 border border-gray-800">
                  <button class="w-8 h-8 rounded-full bg-gray-800 flex items-center justify-center text-white hover:bg-gray-700 transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/></svg>
                  </button>
                  <span class="font-bold w-4 text-center">2</span>
                  <button class="w-8 h-8 rounded-full bg-red-600 flex items-center justify-center text-white hover:bg-red-700 transition-colors shadow-lg shadow-red-600/30">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
                  </button>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Item Card 2 -->
          <div class="bg-[#1e1e1e] rounded-2xl border border-gray-800 overflow-hidden flex flex-col group hover:border-gray-600 transition-colors">
            <div class="h-48 bg-gray-800 relative">
               <img src="https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&q=80" alt="Ribeye" class="w-full h-full object-cover" />
            </div>
            <div class="p-5 flex-1 flex flex-col">
              <h3 class="text-lg font-bold text-white mb-1">Dẻ Sườn Bò Rút Xương</h3>
              <p class="text-sm text-gray-400 mb-4 flex-1">Boneless Short Rib</p>
              
              <div class="flex items-center justify-between mt-auto">
                <span class="text-red-500 font-bold">0đ</span>
                <div class="flex items-center gap-3 bg-black rounded-full p-1 border border-gray-800">
                  <button class="w-8 h-8 rounded-full bg-gray-800 flex items-center justify-center text-gray-500 cursor-not-allowed">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/></svg>
                  </button>
                  <span class="font-bold w-4 text-center">0</span>
                  <button class="w-8 h-8 rounded-full bg-red-600 flex items-center justify-center text-white hover:bg-red-700 transition-colors shadow-lg shadow-red-600/30">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Item Card 3 -->
          <div class="bg-[#1e1e1e] rounded-2xl border border-gray-800 overflow-hidden flex flex-col group hover:border-gray-600 transition-colors">
            <div class="h-48 bg-gray-800 relative">
               <img src="https://images.unsplash.com/photo-1558030006-450675393462?auto=format&fit=crop&q=80" alt="Tongue" class="w-full h-full object-cover" />
            </div>
            <div class="p-5 flex-1 flex flex-col">
              <h3 class="text-lg font-bold text-white mb-1">Lưỡi Bò Thượng Hạng</h3>
              <p class="text-sm text-gray-400 mb-4 flex-1">Premium Beef Tongue</p>
              
              <div class="flex items-center justify-between mt-auto">
                <span class="text-red-500 font-bold">0đ</span>
                <div class="flex items-center gap-3 bg-black rounded-full p-1 border border-gray-800">
                  <button class="w-8 h-8 rounded-full bg-gray-800 flex items-center justify-center text-white hover:bg-gray-700 transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/></svg>
                  </button>
                  <span class="font-bold w-4 text-center">1</span>
                  <button class="w-8 h-8 rounded-full bg-red-600 flex items-center justify-center text-white hover:bg-red-700 transition-colors shadow-lg shadow-red-600/30">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
    
    <!-- Footer actions -->
    <footer class="bg-black border-t border-gray-800 p-4 flex justify-between items-center shrink-0">
      <button class="text-gray-400 hover:text-white px-6 py-2 flex items-center gap-2 font-medium">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/></svg>
        Cần Hỗ Trợ
      </button>
      
      <button class="bg-gray-800 hover:bg-gray-700 text-white px-8 py-3 rounded-xl font-bold flex items-center gap-2 border border-gray-700 transition-colors">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12V7H5a2 2 0 0 1 0-4h14v4"/><path d="M3 5v14a2 2 0 0 0 2 2h16v-5"/><path d="M18 12a2 2 0 0 0 0 4h4v-4Z"/></svg>
        Yêu Cầu Thanh Toán
      </button>
    </footer>
  </div>
</template>
