<template>
  <div class="min-h-screen bg-gray-900 text-white flex flex-col font-sans">
    <!-- Header -->
    <header class="bg-gray-800 border-b border-gray-700 px-6 py-4 flex items-center shadow-md kawaii-shadow z-10">
      <div class="flex items-center space-x-4">
        <TextLogo size="sm" gradient />
        <span class="bg-gray-700 px-3 py-1 rounded-full text-sm font-medium text-gray-300">{{ $t('auto_chi_nhanh_quan_1', 'Chi nhánh Quận 1') }}</span>
      </div>
      <!-- Right cluster: time + manage + language + avatar + logout -->
      <div class="flex items-center gap-4 ml-auto">
        <div class="text-2xl font-mono text-gray-200 font-bold">
          {{ currentTime }}
        </div>
        <button class="kawaii-btn-ghost text-red-400 hover:bg-red-500/20 px-4 py-2 rounded-lg border border-red-500/30 transition-colors flex items-center">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
          </svg>{{ $t('auto_quan_ly_het_mon', 'Quản lý Hết Món') }}</button>
        <LanguageSwitcher />
        <img :src="stickerUrl" alt="User Avatar" class="w-8 h-8 rounded-full border border-[hsl(var(--border))] object-contain bg-[hsl(var(--muted))]" />
        <button class="px-3 py-2 rounded-lg text-sm font-semibold text-gray-200 hover:bg-red-500/20 hover:text-red-400 transition-colors flex items-center" @click="handleSignOut">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
          </svg></button>
      
        <div class="flex items-center gap-2 ml-4 border-l pl-4 border-[hsl(var(--border))]">
          <LanguageSwitcher />
          <img :src="stickerUrl" alt="User Avatar" class="w-8 h-8 rounded-full border border-[hsl(var(--border))] object-contain bg-[hsl(var(--muted))]" />
        </div>
      </div>
      </header>

    <!-- Main Content -->
    <main class="flex-1 overflow-hidden flex flex-col bg-gray-900 p-6">
      <router-view />
    </main>
  </div>
</template>

<script setup lang="ts">
import LanguageSwitcher from '@/components/LanguageSwitcher.vue'
import { ref, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useUserSticker } from '@/composables/useUserSticker'
import TextLogo from '@/components/TextLogo.vue'

const { stickerUrl } = useUserSticker()
const router = useRouter()
const { signOut, profile } = useAuth()

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

async function handleSignOut() {
  await signOut()
  await router.push({ name: 'login' })
}

onMounted(() => {
  updateTime();
  timer = setInterval(updateTime, 1000) as unknown as number;
});

onUnmounted(() => {
  if (timer) clearInterval(timer);
});

void profile
</script>

<style scoped>
/* Any specific local overrides if needed */
</style>
