<template>
  <div class="min-h-screen bg-background text-foreground flex flex-col font-sans">
    <!-- Header -->
    <header class="bg-card border-b border-border px-6 py-4 flex items-center shadow-md kawaii-shadow z-10 z-40">
      <div class="flex items-center space-x-4">
        <TextLogo size="sm" gradient />
        <span class="bg-muted px-3 py-1 rounded-full text-sm font-medium text-muted-foreground">{{ $t('layout.district_1_branch', 'Chi nhánh Quận 1') }}</span>
      </div>
      <!-- Right cluster: time + manage + language + avatar + logout -->
      <div class="flex items-center gap-4 ml-auto">
        <div class="text-2xl font-mono text-foreground font-bold">
          {{ currentTime }}
        </div>
        <button class="kawaii-btn-ghost text-red-400 hover:bg-red-500/20 px-4 py-2 rounded-lg border border-red-500/30 transition-colors flex items-center">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
          </svg>{{ $t('layout.manage_sold_out', 'Quản lý Hết Món') }}</button>
        <div class="flex items-center gap-2 ml-4 border-l pl-4 border-[hsl(var(--border))] border-border">
          <LanguageSwitcher />
          <img :src="stickerUrl" alt="User Avatar" class="w-8 h-8 rounded-full border border-[hsl(var(--border))] object-contain bg-[hsl(var(--muted))]" />
          <button @click="handleSignOut" class="ml-2 bg-muted hover:bg-muted text-foreground px-3 py-1.5 rounded-lg text-sm font-medium transition-colors border border-border">
            {{ $t('layout.logout', 'Đăng xuất') }}
          </button>
        </div>
      </div>
      </header>

    <!-- Main Content -->
    <main class="flex-1 overflow-hidden flex flex-col bg-background p-6">
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
