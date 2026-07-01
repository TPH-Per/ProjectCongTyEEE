<!-- File: src/components/customer/PasscodeInput.vue -->
<template>
  <div class="max-w-md w-full bg-[#161616] border border-gray-800 rounded-3xl p-8 flex flex-col items-center gap-6 shadow-2xl relative overflow-hidden min-h-[580px]">
    
    <!-- Top-left Back Button -->
    <button @click="emit('back')" 
            class="absolute top-6 left-6 flex items-center gap-1.5 text-xs font-bold text-gray-500 hover:text-white bg-gray-900 border border-gray-800 hover:border-gray-700 px-3.5 py-2 rounded-xl transition-all active:scale-95 select-none">
      <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <line x1="19" y1="12" x2="5" y2="12"></line>
        <polyline points="12 19 5 12 12 5"></polyline>
      </svg>
      Quay lại
    </button>

    <!-- Background decorative accents -->
    <div class="absolute -top-10 -right-10 w-40 h-40 bg-amber-500/10 rounded-full blur-3xl pointer-events-none"></div>
    <div class="absolute -bottom-10 -left-10 w-40 h-40 bg-rose-500/5 rounded-full blur-3xl pointer-events-none"></div>

    <!-- Center Brand Logo & Title -->
    <div class="text-center mt-12">
      <div class="w-20 h-20 bg-amber-500/10 border border-amber-500/20 rounded-2xl flex items-center justify-center text-4xl mx-auto mb-4 shadow-lg shadow-amber-500/5 animate-pulse">
        🐂
      </div>
      <h2 class="text-2xl font-black text-amber-500 uppercase tracking-widest">NGƯU CÁT POS</h2>
      <h3 class="text-sm font-bold text-gray-300 mt-2">Xác thực nhân viên</h3>
    </div>

    <!-- Passcode Dots (6 characters) -->
    <div class="flex items-center justify-center gap-4 my-2">
      <div v-for="i in 6" :key="i" 
           :class="[
             'w-4 h-4 rounded-full transition-all duration-150 border-2',
             passcode.length >= i 
               ? 'bg-amber-500 border-amber-500 scale-110 shadow-lg shadow-amber-500/40' 
               : 'bg-transparent border-gray-650'
           ]">
      </div>
    </div>

    <!-- Virtual Numpad Grid -->
    <div class="grid grid-cols-3 gap-4 w-full mt-2">
      <button v-for="num in [1, 2, 3, 4, 5, 6, 7, 8, 9]" :key="num"
              @click="pressKey(String(num))"
              class="h-14 rounded-2xl bg-[#1d1d1d] active:bg-[#282828] border border-gray-805 active:scale-95 text-xl font-bold text-white transition-all flex items-center justify-center select-none">
        {{ num }}
      </button>

      <!-- Bottom Row: Xóa, 0, Xác nhận -->
      <button @click="backspace"
              class="h-14 rounded-2xl bg-[#1d1d1d] active:bg-[#282828] border border-gray-805 active:scale-95 text-xs font-black text-rose-400 active:text-rose-300 transition-all flex items-center justify-center select-none uppercase tracking-wider">
        Xóa
      </button>

      <button @click="pressKey('0')"
              class="h-14 rounded-2xl bg-[#1d1d1d] active:bg-[#282828] border border-gray-805 active:scale-95 text-xl font-bold text-white transition-all flex items-center justify-center select-none">
        0
      </button>

      <button @click="confirm"
              :class="[
                'h-14 rounded-2xl border active:scale-95 text-xs font-black transition-all flex items-center justify-center select-none uppercase tracking-wider',
                passcode.length === 6
                  ? 'bg-amber-500 text-black border-amber-500 shadow-md shadow-amber-500/10'
                  : 'bg-gray-800 text-gray-500 border-gray-705'
              ]">
        Xác nhận
      </button>
    </div>

    <!-- Error message display at the bottom -->
    <div class="h-8 flex items-center justify-center w-full mt-1">
      <transition name="shake">
        <span v-if="error" class="text-rose-400 text-xs font-extrabold bg-rose-500/10 px-4 py-2 rounded-xl border border-rose-500/20 text-center">
          ⚠️ {{ error }}
        </span>
      </transition>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const emit = defineEmits<{
  (e: 'submit', passcode: string): void;
  (e: 'back'): void;
}>();

const passcode = ref('');
const error = ref<string | null>(null);

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
    error.value = 'Mã passcode phải đủ 6 ký tự!';
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
