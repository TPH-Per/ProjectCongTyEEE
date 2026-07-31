<!-- File: src/components/customer/InvoiceRequestModal.vue -->
<template>
  <div v-if="modelValue" class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
    <div class="bg-white rounded-3xl p-6 md:p-8 w-full max-w-lg shadow-2xl relative flex flex-col gap-6 text-[#333333] max-h-[90vh] overflow-y-auto">
      
      <!-- Close Button -->
      <button @click="close" 
              class="absolute top-4 right-4 text-xs font-bold text-gray-400 hover:text-[#333333] px-3 py-1.5 rounded-lg transition-all active:scale-95 select-none">
        ✕
      </button>

      <div class="text-center pt-2 border-b border-gray-100 pb-4">
        <h3 class="text-xl font-black text-[#333333] mb-1.5 font-serif tracking-wide">{{ $t('customer.invoice.title') }}</h3>
        <p class="text-xs text-gray-500">{{ $t('customer.invoice.subtitle') }}</p>
      </div>

      <div class="flex flex-col gap-4">
        <!-- Tax Code Input -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-bold text-[#666666] uppercase tracking-wider">{{ $t('customer.invoice.taxCode') }} <span class="text-red-500">*</span></label>
          <div class="flex gap-2">
            <input v-model="taxCode" 
                   type="text" 
                   :placeholder="$t('customer.invoice.taxCodePlaceholder')"
                   class="flex-1 bg-gray-50 border border-gray-200 focus:border-[#E8772E]/50 rounded-xl p-3 text-sm font-bold text-[#333333] placeholder-gray-455 focus:outline-none transition-colors"
                   @keyup.enter="lookupTaxCode" />
            <button @click="lookupTaxCode" 
                    :disabled="isLookingUp || !taxCode.trim()"
                    class="px-5 rounded-xl bg-gray-800 hover:bg-gray-900 disabled:opacity-50 text-white font-bold text-xs transition-all active:scale-95 shadow-md shrink-0">
              <span v-if="isLookingUp">{{ $t('customer.invoice.lookingUp') }}</span>
              <span v-else>{{ $t('customer.invoice.lookup') }}</span>
            </button>
          </div>
          <span v-if="lookupError" class="text-xs text-red-500 font-bold mt-1">{{ lookupError }}</span>
        </div>

        <!-- Company Name -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-bold text-[#666666] uppercase tracking-wider">{{ $t('customer.invoice.companyName') }}</label>
          <input v-model="companyName" 
                 type="text" 
                 readonly
                 :placeholder="$t('customer.invoice.companyNamePlaceholder')"
                 class="w-full bg-gray-100 border border-gray-200 rounded-xl p-3 text-xs font-bold text-gray-600 focus:outline-none" />
        </div>

        <!-- Company Address -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-bold text-[#666666] uppercase tracking-wider">{{ $t('customer.invoice.companyAddress') }}</label>
          <textarea v-model="companyAddress" 
                    readonly
                    rows="2"
                    :placeholder="$t('customer.invoice.companyAddressPlaceholder')"
                    class="w-full bg-gray-100 border border-gray-200 rounded-xl p-3 text-xs font-bold text-gray-600 focus:outline-none resize-none"></textarea>
        </div>

        <!-- Email for Invoice -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-bold text-[#666666] uppercase tracking-wider">{{ $t('customer.invoice.email') }} <span class="text-red-500">*</span></label>
          <input v-model="email" 
                 type="email" 
                 :placeholder="$t('customer.invoice.emailPlaceholder')"
                 class="w-full bg-gray-50 border border-gray-200 focus:border-[#E8772E]/50 rounded-xl p-3 text-sm font-bold text-[#333333] placeholder-gray-455 focus:outline-none transition-colors" />
        </div>

        <!-- Phone for Invoice -->
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-bold text-[#666666] uppercase tracking-wider">{{ $t('customer.invoice.phone') }} <span class="text-red-500">*</span></label>
          <input v-model="phone" 
                 type="tel" 
                 :placeholder="$t('customer.invoice.phonePlaceholder')"
                 class="w-full bg-gray-50 border border-gray-200 focus:border-[#E8772E]/50 rounded-xl p-3 text-sm font-bold text-[#333333] placeholder-gray-455 focus:outline-none transition-colors" />
        </div>
      </div>

      <!-- Actions Buttons -->
      <div class="flex justify-end gap-3 shrink-0 pt-4 border-t border-gray-100">
        <button @click="close" 
                class="h-11 px-5 rounded-xl border border-gray-200 text-gray-500 hover:text-[#333333] font-bold text-xs transition-colors active:scale-95 bg-gray-50">
          {{ $t('customer.invoice.cancel') }}
        </button>
        
        <button @click="submit" 
                :disabled="isSubmitDisabled"
                class="h-11 px-6 rounded-xl bg-[#E8772E] hover:bg-amber-600 disabled:opacity-50 text-white font-extrabold text-xs tracking-wider uppercase transition-all active:scale-95 shadow-md">
          {{ $t('customer.invoice.submit') }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useI18nStore } from '@/stores/i18n';

const i18nStore = useI18nStore();

const props = defineProps<{
  modelValue: boolean;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', val: boolean): void;
  (e: 'submit', data: { taxCode: string; companyName: string; companyAddress: string; email: string; phone: string }): void;
}>();

const taxCode = ref('');
const companyName = ref('');
const companyAddress = ref('');
const email = ref('');
const phone = ref('');

const isLookingUp = ref(false);
const lookupError = ref('');

const isSubmitDisabled = computed(() => {
  return !taxCode.value.trim() || !companyName.value.trim() || !email.value.trim() || !email.value.includes('@') || !phone.value.trim();
});

async function lookupTaxCode() {
  if (!taxCode.value.trim()) return;
  
  isLookingUp.value = true;
  lookupError.value = '';
  companyName.value = '';
  companyAddress.value = '';
  
  try {
    const res = await fetch(`https://api.vietqr.io/v2/business/${taxCode.value.trim()}`);
    if (!res.ok) throw new Error('Network response was not ok');
    
    const json = await res.json();
    if (json.code === '00' && json.data) {
      companyName.value = json.data.name || '';
      companyAddress.value = json.data.address || '';
    } else {
      lookupError.value = i18nStore.t('customer.invoice.errorNotFound');
    }
  } catch (err) {
    lookupError.value = i18nStore.t('customer.invoice.errorLookup');
  } finally {
    isLookingUp.value = false;
  }
}

function close() {
  emit('update:modelValue', false);
}

function submit() {
  if (isSubmitDisabled.value) return;
  emit('submit', {
    taxCode: taxCode.value.trim(),
    companyName: companyName.value.trim(),
    companyAddress: companyAddress.value.trim(),
    email: email.value.trim(),
    phone: phone.value.trim()
  });
  close();
}
</script>
