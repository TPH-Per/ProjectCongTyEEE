<template>
  <div class="flex-1 flex flex-col items-center justify-center bg-[#111111] p-8">
    <h1 class="text-4xl font-bold mb-12 text-center text-white">Please Select Your Language<br><span class="text-2xl text-gray-400 font-medium mt-2 block">言語を選択してください / Vui lòng chọn ngôn ngữ</span></h1>
    
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 w-full max-w-4xl">
      <button class="bg-[#1e1e1e] border-2 border-gray-800 hover:border-red-500 rounded-3xl p-10 flex flex-col items-center justify-center gap-6 transition-all transform hover:-translate-y-2 group">
        <span class="text-7xl group-hover:scale-110 transition-transform">🇯🇵</span>
        <span class="text-2xl font-bold text-white">日本語</span>
      </button>
      
      <button class="bg-[#1e1e1e] border-2 border-gray-800 hover:border-red-500 rounded-3xl p-10 flex flex-col items-center justify-center gap-6 transition-all transform hover:-translate-y-2 group">
        <span class="text-7xl group-hover:scale-110 transition-transform">🇺🇸</span>
        <span class="text-2xl font-bold text-white">English</span>
      </button>
      
      <button class="bg-[#1e1e1e] border-2 border-gray-800 hover:border-red-500 rounded-3xl p-10 flex flex-col items-center justify-center gap-6 transition-all transform hover:-translate-y-2 group">
        <span class="text-7xl group-hover:scale-110 transition-transform">🇻🇳</span>
        <span class="text-2xl font-bold text-white">Tiếng Việt</span>
      </button>
    </div>
  </div>
</template>
