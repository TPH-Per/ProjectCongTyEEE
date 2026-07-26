<!-- File: src/components/customer/PasscodeInput.vue -->
<template>
  <div class="max-w-md w-full bg-[#141416]/95 backdrop-blur-2xl border border-white/10 rounded-3xl p-8 flex flex-col items-center justify-center gap-6 shadow-2xl shadow-black/80 relative min-h-[580px]">
    
    <!-- Top-left Back Button -->
    <button v-if="showBack"
            @click="emit('back')" 
            type="button"
            class="absolute top-6 left-6 flex items-center gap-2 text-xs font-bold text-gray-400 hover:text-white bg-white/5 hover:bg-white/10 border border-white/10 hover:border-white/20 px-3.5 py-2 rounded-xl transition-all active:scale-95 select-none backdrop-blur-md">
      <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <line x1="19" y1="12" x2="5" y2="12"></line>
        <polyline points="12 19 5 12 12 5"></polyline>
      </svg>
      {{ $t('customer.passcode.back') }}
    </button>

    <!-- Background decorative accents -->
    <div class="absolute -top-16 -right-16 w-48 h-48 bg-amber-500/15 rounded-full blur-3xl pointer-events-none"></div>
    <div class="absolute -bottom-16 -left-16 w-48 h-48 bg-rose-500/10 rounded-full blur-3xl pointer-events-none"></div>

    <!-- Center Brand Logo & Title -->
    <div class="text-center mt-8">
      <div class="w-20 h-20 bg-gradient-to-br from-amber-500/20 to-amber-600/5 border border-amber-500/30 rounded-2xl flex items-center justify-center text-4xl mx-auto mb-4 shadow-xl shadow-amber-500/10 animate-pulse backdrop-blur-md">
        🐂
      </div>
      <h2 class="text-2xl font-black text-transparent bg-clip-text bg-gradient-to-r from-amber-400 via-amber-500 to-amber-600 uppercase tracking-widest">{{ $t('customer.passcode.title') }}</h2>
      <h3 class="text-sm font-bold text-gray-300 mt-2 tracking-wide">{{ $t('customer.passcode.subtitle') }}</h3>
    </div>

    <!-- Passcode Dots (6 characters) -->
    <div class="flex items-center justify-center gap-4 my-2">
      <div v-for="i in 6" :key="i" 
           :class="[
             'w-4 h-4 rounded-full transition-all duration-200 border-2',
             passcode.length >= i 
               ? 'bg-amber-500 border-amber-400 scale-110 shadow-lg shadow-amber-500/50' 
               : 'bg-white/5 border-gray-700'
           ]">
      </div>
    </div>

    <!-- Virtual Numpad Grid -->
    <div class="grid grid-cols-3 gap-3.5 w-full mt-2">
      <button v-for="num in [1, 2, 3, 4, 5, 6, 7, 8, 9]" :key="num"
              type="button"
              @click="pressKey(String(num))"
              class="h-14 rounded-2xl bg-[#1e1e22] hover:bg-[#282830] active:bg-[#323240] border border-white/10 hover:border-amber-500/40 active:scale-95 text-2xl font-black text-white transition-all flex items-center justify-center select-none shadow-md">
        {{ num }}
      </button>

      <!-- Bottom Row: Xóa, 0, Xác nhận -->
      <button @click="backspace"
              type="button"
              class="h-14 rounded-2xl bg-rose-500/15 hover:bg-rose-500/25 active:bg-rose-500/35 border border-rose-500/30 active:scale-95 text-xs font-black text-rose-300 active:text-rose-200 transition-all flex items-center justify-center select-none uppercase tracking-wider shadow-md px-1">
        ⌫ {{ $t('customer.passcode.delete') }}
      </button>

      <button @click="pressKey('0')"
              type="button"
              class="h-14 rounded-2xl bg-[#1e1e22] hover:bg-[#282830] active:bg-[#323240] border border-white/10 hover:border-amber-500/40 active:scale-95 text-2xl font-black text-white transition-all flex items-center justify-center select-none shadow-md">
        0
      </button>

      <button @click="confirm"
              type="button"
              :class="[
                'h-14 rounded-2xl border active:scale-95 text-xs font-black transition-all flex items-center justify-center select-none uppercase tracking-wider shadow-md px-1',
                passcode.length === 6
                  ? 'bg-gradient-to-r from-amber-500 to-amber-600 text-black border-amber-400 shadow-amber-500/30 hover:brightness-110 font-extrabold'
                  : 'bg-white/5 text-gray-500 border-white/5 cursor-not-allowed'
              ]">
        ✓ {{ $t('customer.passcode.confirm') }}
      </button>
    </div>

    <!-- Error message display at the bottom -->
    <div class="h-8 flex items-center justify-center w-full mt-1">
      <transition name="shake">
        <span v-if="error" class="text-rose-400 text-xs font-extrabold bg-rose-500/10 px-4 py-2 rounded-xl border border-rose-500/20 text-center shadow-lg backdrop-blur-md">
          ⚠️ {{ error }}
        </span>
      </transition>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useI18nStore } from '@/stores/i18n';

const props = defineProps({
  showBack: { type: Boolean, default: true }
});

const emit = defineEmits<{
  (e: 'submit', passcode: string): void;
  (e: 'back'): void;
}>();

const passcode = ref('');
const error = ref<string | null>(null);
const i18nStore = useI18nStore();
const t = i18nStore.t;

function pressKey(key: string) {
  error.value = null;
  if (passcode.value.length < 6) {
    passcode.value += key;
  }
}

function backspace() {
  error.value = null;
  if (passcode.value.length > 0) {
    passcode.value = passcode.value.slice(0, -1);
  }
}

function confirm() {
  error.value = null;
  if (passcode.value.length !== 6) {
    error.value = t('customer.passcode.errorLength');
    return;
  }
  emit('submit', passcode.value);
}

function setError(msg: string) {
  error.value = msg;
  // Trigger shake animation
  const dots = document.querySelectorAll('.rounded-full');
  dots.forEach(el => el.classList.add('shake-anim'));
  setTimeout(() => {
    dots.forEach(el => el.classList.remove('shake-anim'));
  }, 500);
  passcode.value = '';
}

function clear() {
  error.value = null;
  passcode.value = '';
}

defineExpose({
  setError,
  clear
});
</script>

<style scoped>
.shake-enter-active {
  animation: shake 0.3s ease;
}
@keyframes shake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-8px); }
  75% { transform: translateX(8px); }
}
.shake-anim {
  animation: dot-shake 0.5s ease-in-out;
}
@keyframes dot-shake {
  0%, 100% { transform: translateX(0); }
  20%, 60% { transform: translateX(-4px); }
  40%, 80% { transform: translateX(4px); }
}
</style>
