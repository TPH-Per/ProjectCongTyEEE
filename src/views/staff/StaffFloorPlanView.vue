<template>
  <div class="p-4">
    <div class="flex items-center justify-between mb-6">
      <h2 class="text-xl font-bold text-gray-800">Sơ đồ bàn</h2>
      <div class="bg-red-50 text-red-600 px-3 py-1 rounded-full text-xs font-bold">
        3 Đang phục vụ
      </div>
    </div>

    <div class="grid grid-cols-2 gap-4">
      <!-- Active Table -->
      <RouterLink to="/staff/table/T1-A4/crm" class="bg-white border-2 border-red-500 rounded-2xl p-4 shadow-sm relative overflow-hidden flex flex-col h-32">
        <div class="absolute top-0 left-0 w-full h-1 bg-red-500"></div>
        <div class="flex justify-between items-start mb-2">
          <span class="font-bold text-lg text-gray-900">T1-A4</span>
          <span class="bg-red-100 text-red-700 text-[10px] font-bold px-2 py-0.5 rounded">Dining</span>
        </div>
        <div class="text-xs text-gray-500 mb-1">Buffet 1380k + Drink A</div>
        <div class="text-xs text-gray-500 font-medium mt-auto">Khách: 4 (2 Nam, 2 Nữ)</div>
      </RouterLink>

      <!-- Idle Table -->
      <RouterLink to="/staff/table/T1-B1/open" class="bg-white border border-gray-200 rounded-2xl p-4 shadow-sm relative flex flex-col h-32 opacity-80 hover:opacity-100 hover:border-gray-300 transition-all">
        <div class="flex justify-between items-start mb-2">
          <span class="font-bold text-lg text-gray-900">T1-B1</span>
          <span class="bg-gray-100 text-gray-500 text-[10px] font-bold px-2 py-0.5 rounded">Trống</span>
        </div>
        <div class="mt-auto flex justify-center">
          <div class="text-xs font-bold text-red-600 flex items-center gap-1">
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
            Mở bàn
          </div>
        </div>
      </RouterLink>

      <!-- Idle Table -->
      <RouterLink to="/staff/table/T1-B2/open" class="bg-white border border-gray-200 rounded-2xl p-4 shadow-sm relative flex flex-col h-32 opacity-80 hover:opacity-100 hover:border-gray-300 transition-all">
        <div class="flex justify-between items-start mb-2">
          <span class="font-bold text-lg text-gray-900">T1-B2</span>
          <span class="bg-gray-100 text-gray-500 text-[10px] font-bold px-2 py-0.5 rounded">Trống</span>
        </div>
        <div class="mt-auto flex justify-center">
          <div class="text-xs font-bold text-red-600 flex items-center gap-1">
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
            Mở bàn
          </div>
        </div>
      </RouterLink>

      <!-- Checkout Requested Table -->
      <RouterLink to="/staff/table/T2-A1/crm" class="bg-yellow-50 border-2 border-yellow-400 rounded-2xl p-4 shadow-sm relative flex flex-col h-32 animate-pulse">
        <div class="flex justify-between items-start mb-2">
          <span class="font-bold text-lg text-yellow-900">T2-A1</span>
          <span class="bg-yellow-200 text-yellow-800 text-[10px] font-bold px-2 py-0.5 rounded">Checkout</span>
        </div>
        <div class="mt-auto text-xs font-medium text-yellow-700 text-center">
          Khách đang ra quầy
        </div>
      </RouterLink>
    </div>
  </div>
</template>
