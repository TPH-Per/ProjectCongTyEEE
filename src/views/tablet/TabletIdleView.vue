<template>
  <div class="flex-1 flex flex-col items-center justify-center relative p-8">
    <div class="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1541535882678-578f44ce2f5c?auto=format&fit=crop&q=80')] bg-cover bg-center opacity-20"></div>
    
    <div class="relative z-10 flex flex-col items-center max-w-lg w-full">
      <div class="w-32 h-32 rounded-3xl bg-red-600 flex items-center justify-center text-white font-black text-6xl shadow-2xl mb-8 transform -rotate-3">
        🐂
      </div>
      
      <h1 class="text-6xl font-black mb-4 tracking-tighter">NGƯU CÁT</h1>
      <p class="text-2xl text-gray-400 font-bold mb-16">Ira-shai-Mase !!</p>
      
      <div class="bg-white p-8 rounded-3xl shadow-2xl flex flex-col items-center w-full">
        <div class="text-gray-900 font-bold text-xl mb-6">Mã kết nối bàn</div>
        <!-- Mock QR Code -->
        <div class="w-48 h-48 bg-gray-200 rounded-xl mb-6 flex items-center justify-center">
          <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" class="text-gray-500"><rect width="5" height="5" x="3" y="3" rx="1"/><rect width="5" height="5" x="16" y="3" rx="1"/><rect width="5" height="5" x="3" y="16" rx="1"/><path d="M21 16h-3a2 2 0 0 0-2 2v3"/><path d="M21 21v.01"/><path d="M12 7v3a2 2 0 0 1-2 2H7"/><path d="M3 12h.01"/><path d="M12 3h.01"/><path d="M12 16v.01"/><path d="M16 12h1"/><path d="M21 12v.01"/><path d="M12 21v-1"/></svg>
        </div>
        <div class="text-4xl font-black text-red-600 tracking-widest bg-red-50 px-6 py-3 rounded-xl border-2 border-red-100">
          T1-A4
        </div>
        <p class="text-gray-500 font-medium text-sm mt-4 text-center">Vui lòng chờ nhân viên quét mã để bắt đầu dùng bữa.</p>
      </div>
    </div>
  </div>
</template>
