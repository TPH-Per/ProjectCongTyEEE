<template>
  <div>
    <div class="mb-6 flex items-center gap-3">
      <RouterLink to="/reception/dashboard" class="w-10 h-10 rounded-xl bg-white border flex items-center justify-center text-gray-600 hover:bg-gray-50 transition-colors">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg>
      </RouterLink>
      <div>
        <h2 class="text-2xl font-bold text-gray-900">Thanh Toán: Bàn T2-A1</h2>
        <div class="flex items-center gap-2">
          <span class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
          <p class="text-sm text-red-600 font-bold">Yêu Cầu Thanh Toán lúc 15:20</p>
        </div>
      </div>
    </div>

    <!-- Communication Script -->
    <div class="bg-blue-50 border border-blue-200 rounded-2xl p-5 mb-6 flex gap-4 shadow-sm">
      <div class="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center shrink-0">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-blue-600"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
      </div>
      <div>
        <h3 class="text-sm font-bold text-blue-900 mb-1">Kịch bản Lễ Tân (Thu Ngân hỏi khách)</h3>
        <p class="text-blue-800 font-medium italic">"Dạ em chào anh/chị. Hôm nay anh/chị dùng bữa có ngon miệng không ạ? Mọi thứ đều ổn chứ ạ?"</p>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      
      <!-- Left Column: CRM & Info -->
      <div class="lg:col-span-2 space-y-6">
        
        <!-- Member Check -->
        <div class="bg-white border rounded-2xl p-6 shadow-sm">
          <h3 class="text-base font-bold text-gray-900 mb-4 border-b pb-3">1. Định Danh Khách Hàng (Membership)</h3>
          
          <div class="flex gap-3 mb-6">
            <input type="text" placeholder="Nhập số điện thoại khách hàng..." class="flex-1 bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base focus:outline-none focus:border-red-500 font-semibold" value="0987654321" />
            <button class="bg-gray-900 text-white px-6 py-3 rounded-xl font-bold hover:bg-black transition-colors">
              Tra Cứu
            </button>
          </div>

          <!-- Member Found State -->
          <div class="bg-green-50 border border-green-200 rounded-xl p-4 flex gap-4">
            <div class="w-12 h-12 bg-green-100 text-green-600 rounded-full flex items-center justify-center font-bold text-xl shrink-0">
              V
            </div>
            <div class="flex-1">
              <div class="flex justify-between items-start">
                <div>
                  <h4 class="font-bold text-gray-900 text-lg">Nguyễn Văn A</h4>
                  <div class="text-sm text-gray-600 mb-2">SĐT: 0987654321 • Zalo OA: Đã liên kết</div>
                </div>
                <div class="bg-red-100 text-red-700 px-3 py-1 rounded-full text-xs font-bold border border-red-200">
                  Khách Quen (Repeater)
                </div>
              </div>
              
              <div class="grid grid-cols-2 gap-4 mt-2">
                <div class="bg-white p-2 rounded border border-green-100">
                  <span class="text-xs text-gray-500 block">Số lần đến</span>
                  <span class="font-bold text-gray-900">4 lần</span>
                </div>
                <div class="bg-white p-2 rounded border border-green-100">
                  <span class="text-xs text-gray-500 block">Ưu đãi hiện có</span>
                  <span class="font-bold text-green-600">Giảm 10% Bill</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Promo & Revenue Type -->
        <div class="bg-white border rounded-2xl p-6 shadow-sm">
          <h3 class="text-base font-bold text-gray-900 mb-4 border-b pb-3">2. Phân Loại Hóa Đơn & Voucher</h3>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label class="block text-sm font-bold text-gray-700 mb-2">Loại Doanh Thu (Bắt buộc)</label>
              <select class="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base font-semibold focus:outline-none focus:border-red-500 text-gray-900 appearance-none">
                <option value="dinner" selected>Bữa Tối (Dinner)</option>
                <option value="lunch">Bữa Trưa (Lunch)</option>
                <option value="wine">Chỉ uống Rượu/Cocktail</option>
                <option value="delivery">Giao Hàng (Delivery)</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-bold text-gray-700 mb-2">Nhập/Quét Mã Voucher</label>
              <div class="flex gap-2">
                <input type="text" placeholder="VD: TET2024..." class="flex-1 w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-base focus:outline-none focus:border-red-500 uppercase font-semibold text-gray-900" />
                <button class="bg-gray-200 text-gray-700 px-4 py-3 rounded-xl font-bold hover:bg-gray-300 transition-colors shrink-0">
                  Áp Dụng
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- In-Dining CRM Data -->
        <div class="bg-white border rounded-2xl p-6 shadow-sm">
          <h3 class="text-base font-bold text-gray-900 mb-4 border-b pb-3">3. Dữ liệu thu thập tại bàn (Bởi Nhân Viên)</h3>
          <div class="grid grid-cols-2 gap-y-4">
            <div>
              <span class="text-sm text-gray-500 block">Kênh Marketing</span>
              <span class="font-bold text-gray-900">Người quen giới thiệu</span>
            </div>
            <div>
              <span class="text-sm text-gray-500 block">Xin phép chụp ảnh</span>
              <span class="font-bold text-green-600">Đồng ý</span>
            </div>
            <div>
              <span class="text-sm text-gray-500 block">Trạng thái Voucher</span>
              <span class="font-bold text-blue-600">NV đã tặng Voucher giấy 10%</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Right Column: Bill Summary -->
      <div class="bg-white border rounded-2xl p-0 shadow-sm flex flex-col overflow-hidden">
        <div class="p-6 border-b bg-gray-50">
          <h3 class="text-lg font-bold text-gray-900">Tổng Kết Hóa Đơn</h3>
          <p class="text-sm text-gray-500">Bàn T2-A1 • 4 Khách</p>
        </div>
        
        <div class="p-6 flex-1 overflow-y-auto">
          <div class="space-y-3 mb-6">
            <div class="flex justify-between items-center">
              <span class="font-bold text-gray-700">4 x Set Biz 1200k</span>
              <span class="font-bold text-gray-900">4,800,000đ</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-gray-600 pl-4">Thăn Ngoại Wagyu (x4)</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-gray-600 pl-4">Lưỡi Bò Thượng Hạng (x2)</span>
            </div>
            <div class="flex justify-between items-center pt-3 border-t border-dashed">
              <span class="font-bold text-gray-700">4 x Drink A</span>
              <span class="font-bold text-gray-900">0đ</span>
            </div>
          </div>

          <div class="space-y-3 pt-4 border-t">
            <div class="flex justify-between items-center">
              <span class="text-gray-500">Tạm tính</span>
              <span class="font-semibold text-gray-900">4,800,000đ</span>
            </div>
            <div class="flex justify-between items-center text-green-600">
              <span class="font-bold">Giảm giá Repeater (10%)</span>
              <span class="font-bold">-480,000đ</span>
            </div>
            <div class="flex justify-between items-center text-gray-500">
              <span>VAT (8%)</span>
              <span>345,600đ</span>
            </div>
          </div>
        </div>

        <div class="p-6 bg-gray-50 border-t">
          <div class="flex justify-between items-end mb-6">
            <span class="text-gray-700 font-bold">Thành Tiền</span>
            <span class="text-3xl font-black text-red-600">4,665,600đ</span>
          </div>
          
          <button class="w-full bg-red-600 hover:bg-red-700 text-white font-bold py-4 rounded-xl shadow-lg transition-colors text-lg flex items-center justify-center gap-2 mb-3">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect width="12" height="8" x="6" y="14"/></svg>
            In Hóa Đơn & Đóng Bàn
          </button>

          <p class="text-xs text-center text-gray-500 font-medium">Nhớ nhờ khách đánh giá Google Map nhé!</p>
        </div>
      </div>
    </div>
  </div>
</template>
