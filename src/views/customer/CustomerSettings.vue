<!-- File: src/views/customer/CustomerSettings.vue -->
<template>
  <div class="w-full h-full flex flex-col overflow-hidden bg-[#0d0d0f]">

    <!-- Sub Header Bar -->
    <div class="px-6 md:px-8 py-4 bg-[#141417] border-b border-white/10 flex items-center justify-between shrink-0">
      <div>
        <h1 class="text-lg md:text-xl font-black text-white font-serif tracking-wide">{{ $t('customer.settings.title') }}</h1>
        <p class="text-[10px] text-gray-400 mt-0.5">{{ $t('customer.settings.subtitle') }}</p>
      </div>
      <button @click="goBack"
              class="w-9 h-9 rounded-lg flex items-center justify-center border bg-[#2a1b10] border-[#442c19] text-gray-400 hover:text-white transition-all active:scale-90">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="19" y1="12" x2="5" y2="12"></line>
          <polyline points="12 19 5 12 12 5"></polyline>
        </svg>
      </button>
    </div>

    <!-- Content Area -->
    <div class="flex-1 overflow-y-auto p-6 md:p-8">
      <div class="max-w-lg mx-auto flex flex-col gap-6">

        <!-- Language Setting -->
        <div class="bg-[#1e1e24] border border-white/10 rounded-2xl p-6 flex flex-col gap-4">
          <h3 class="text-sm font-black text-white uppercase tracking-wider flex items-center gap-2">
            <span>🌐</span> {{ $t('customer.settings.language') }}
          </h3>
          <div class="flex items-center gap-3">
            <button v-for="lang in languages" :key="lang.code"
                    @click="setLanguage(lang.code)"
                    :class="[
                      'flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl border text-xs font-bold transition-all active:scale-95',
                      i18nStore.locale === lang.code
                        ? 'bg-[#E8772E] border-[#E8772E] text-black'
                        : 'bg-[#2a1b10] border-[#442c19] text-gray-400 hover:text-white'
                    ]">
              <span class="text-base">{{ lang.flag }}</span>
              <span>{{ lang.label }}</span>
            </button>
          </div>
        </div>

        <!-- Back to Menu Button -->
        <button @click="goBack"
                class="w-full h-12 rounded-xl bg-[#E8772E] hover:bg-amber-600 text-white font-extrabold text-xs tracking-wider uppercase transition-all active:scale-95 shadow-md flex items-center justify-center gap-2">
          <span>←</span> {{ $t('customer.settings.backToMenu') }}
        </button>

      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router';
import { useCustomerStore } from '@/stores/customerStore';
import { useI18nStore } from '@/stores/i18n';

const router = useRouter();
const store = useCustomerStore();
const i18nStore = useI18nStore();

const languages = [
  { code: 'vi' as const, flag: '🇻🇳', label: 'Tiếng Việt' },
  { code: 'en' as const, flag: '🇬🇧', label: 'English' },
  { code: 'ja' as const, flag: '🇯🇵', label: '日本語' },
];

function setLanguage(lang: 'vi' | 'en' | 'ja') {
  i18nStore.setLocale(lang);
  const langName = lang === 'vi' ? 'Tiếng Việt' : lang === 'en' ? 'English' : '日本語';
  store.addNotification(i18nStore.t('customer.languageChanged', { lang: langName }), 'info');
}

function goBack() {
  router.push({ name: 'CustomerMenu' });
}
</script>
