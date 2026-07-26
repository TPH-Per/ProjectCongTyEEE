<template>
  <div v-if="modelValue" class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
    <div class="bg-white rounded-3xl p-6 md:p-8 w-full max-w-sm shadow-2xl relative flex flex-col gap-6 text-[#333333]">
      
      <!-- Close Button -->
      <button @click="close" 
              class="absolute top-4 right-4 text-xs font-bold text-gray-400 hover:text-[#333333] px-3 py-1.5 rounded-lg transition-all active:scale-95 select-none">
        ✕
      </button>

      <div class="text-center pt-2 border-b border-gray-100 pb-4">
        <h3 class="text-xl font-black text-[#333333] mb-1.5 font-serif tracking-wide">{{ $t('customer.crm.title') }}</h3>
        <p class="text-xs text-gray-500">{{ $t('customer.crm.subtitle') }}</p>
      </div>

      <div class="flex flex-col gap-4">
        <!-- Phone Number Input -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-bold text-[#666666] uppercase tracking-wider">{{ $t('customer.crm.phone') }} <span class="text-red-500">*</span></label>
          <input v-model="phone" 
                 type="tel" 
                 :placeholder="$t('customer.crm.phonePlaceholder')"
                 class="w-full bg-gray-50 border border-gray-200 focus:border-[#E8772E]/50 rounded-xl p-3 text-sm font-bold text-[#333333] placeholder-gray-400 focus:outline-none transition-colors" />
        </div>

        <!-- Customer Name Input -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-bold text-[#666666] uppercase tracking-wider">{{ $t('customer.crm.name') }}</label>
          <input v-model="name" 
                 type="text" 
                 :placeholder="$t('customer.crm.namePlaceholder')"
                 class="w-full bg-gray-50 border border-gray-200 focus:border-[#E8772E]/50 rounded-xl p-3 text-sm font-bold text-[#333333] placeholder-gray-400 focus:outline-none transition-colors" />
        </div>
      </div>

      <!-- Actions Buttons -->
      <div class="flex justify-end gap-3 shrink-0 pt-4 border-t border-gray-100">
        <button @click="close" 
                class="h-11 px-5 rounded-xl border border-gray-200 text-gray-500 hover:text-[#333333] font-bold text-xs transition-colors active:scale-95 bg-gray-50">
          {{ $t('customer.crm.cancel') }}
        </button>
        
        <button @click="submit" 
                :disabled="!isValid"
                class="h-11 px-6 rounded-xl bg-[#E8772E] hover:bg-amber-600 disabled:opacity-50 text-white font-extrabold text-xs tracking-wider uppercase transition-all active:scale-95 shadow-md">
          {{ $t('customer.crm.submit') }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';

const props = defineProps<{
  modelValue: boolean;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', val: boolean): void;
  (e: 'submit', data: { phone: string; name: string }): void;
}>();

const phone = ref('');
const name = ref('');

const isValid = computed(() => {
  return phone.value.trim().length >= 10;
});

function close() {
  emit('update:modelValue', false);
}

function submit() {
  if (!isValid.value) return;
  emit('submit', {
    phone: phone.value.trim(),
    name: name.value.trim(),
  });
  close();
}
</script>
