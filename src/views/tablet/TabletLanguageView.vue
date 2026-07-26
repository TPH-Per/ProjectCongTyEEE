<template>
  <div class="flex-1 flex flex-col items-center justify-center bg-[#111111] p-8">

    <h1 class="text-4xl font-bold mb-12 text-center text-white">{{ $t('tablet.select_language') }}</h1>
    
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 w-full max-w-4xl">
      <button @click="selectLanguage('ja')" class="bg-[#1e1e1e] border-2 border-gray-800 hover:border-red-500 rounded-3xl p-10 flex flex-col items-center justify-center gap-6 transition-all transform hover:-translate-y-2 group">
        <span class="text-7xl group-hover:scale-110 transition-transform">🇯🇵</span>
        <span class="text-2xl font-bold text-white">日本語</span>
      </button>
      
      <button @click="selectLanguage('en')" class="bg-[#1e1e1e] border-2 border-gray-800 hover:border-red-500 rounded-3xl p-10 flex flex-col items-center justify-center gap-6 transition-all transform hover:-translate-y-2 group">
        <span class="text-7xl group-hover:scale-110 transition-transform">🇺🇸</span>
        <span class="text-2xl font-bold text-white">English</span>
      </button>
      
      <button @click="selectLanguage('vi')" class="bg-[#1e1e1e] border-2 border-gray-800 hover:border-red-500 rounded-3xl p-10 flex flex-col items-center justify-center gap-6 transition-all transform hover:-translate-y-2 group">
        <span class="text-7xl group-hover:scale-110 transition-transform">🇻🇳</span>
        <span class="text-2xl font-bold text-white">Tiếng Việt</span>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useTablet } from '@/composables/useTablet';

const router = useRouter();
const route = useRoute();
const { t } = useI18n();
const { setLanguage } = useTablet();

const tableId = (route.query.table_id as string) || 'default-table';

async function selectLanguage(lang: 'vi' | 'en' | 'ja') {
  await setLanguage(tableId, lang);
  router.push({ name: 'tablet-order', query: route.query });
}
</script>
