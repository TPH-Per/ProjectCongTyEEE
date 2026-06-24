<template>
  <div class="min-h-screen bg-gray-900 text-white flex flex-col font-sans">
    <!-- Header -->
    <header class="bg-gray-800 border-b border-gray-700 px-6 py-4 flex items-center justify-between shadow-md kawaii-shadow z-10">
      <div class="flex items-center space-x-4">
        <h1 class="text-2xl font-bold text-[#FF7B89]">Ngưu Cát KDS</h1>
        <span class="bg-gray-700 px-3 py-1 rounded-full text-sm font-medium text-gray-300">Chi nhánh Quận 1</span>
      </div>
      
      <div class="flex items-center space-x-6">
        <div class="text-2xl font-mono text-gray-200 font-bold">
          {{ currentTime }}
        </div>
        <button class="kawaii-btn-ghost text-red-400 hover:bg-red-500/20 px-4 py-2 rounded-lg border border-red-500/30 transition-colors flex items-center">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
          </svg>
          Quản lý Hết Món
        </button>
      </div>
    </header>

    <!-- Main Content -->
    <main class="flex-1 overflow-hidden flex flex-col bg-gray-900 p-6">
      <router-view />
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue';

const currentTime = ref('');
let timer: number | null = null;

const updateTime = () => {
  const now = new Date();
  currentTime.value = now.toLocaleTimeString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  });
};

onMounted(() => {
  updateTime();
  timer = setInterval(updateTime, 1000) as unknown as number;
});

onUnmounted(() => {
  if (timer) clearInterval(timer);
});
</script>

<style scoped>
/* Any specific local overrides if needed */
</style>
