<!-- File: src/views/customer/CustomerProfile.vue -->
<template>
  <div class="w-full h-full flex flex-col overflow-hidden bg-[#0d0d0f]">

    <!-- Sub Header Bar -->
    <div class="px-6 md:px-8 py-4 bg-[#141417] border-b border-white/10 flex items-center justify-between shrink-0">
      <div>
        <h1 class="text-lg md:text-xl font-black text-white font-serif tracking-wide">{{ $t('customer.profile.title') }}</h1>
        <p class="text-[10px] text-gray-400 mt-0.5">{{ $t('customer.profile.subtitle') }}</p>
      </div>
      <button @click="goBack"
              class="w-9 h-9 rounded-lg flex items-center justify-center border bg-[#2a1b10] border-[#442c19] text-gray-400 hover:text-white transition-all active:scale-90">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="19" y1="12" x2="5" y2="12"></line>
          <polyline points="12 19 5 12 12 5"></polyline>
        </svg>
      </button>
    </div>

    <!-- Scrollable Form Area -->
    <div class="flex-1 overflow-y-auto p-6 md:p-8">
      <div class="max-w-lg mx-auto">

        <!-- Form Card -->
        <div class="bg-white rounded-2xl p-6 md:p-8 shadow-sm flex flex-col gap-6 text-[#333333]">

          <!-- Avatar -->
          <div class="flex flex-col items-center gap-3 pb-4 border-b border-gray-100">
            <div class="w-20 h-20 rounded-full bg-gradient-to-br from-[#E8772E] to-amber-600 flex items-center justify-center text-2xl font-black text-white shadow-lg">
              {{ avatarInitial }}
            </div>
            <p class="text-xs text-gray-400 font-bold">{{ $t('customer.profile.personalInfo') }}</p>
          </div>

          <!-- Section 1: Personal Info -->
          <div class="flex flex-col gap-4">
            <!-- Full Name -->
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-bold text-[#666666] uppercase tracking-wider">{{ $t('customer.profile.fullName') }} <span class="text-red-500">*</span></label>
              <input v-model="form.fullName"
                     type="text"
                     :placeholder="$t('customer.profile.fullNamePlaceholder')"
                     class="w-full bg-gray-50 border border-gray-200 focus:border-[#E8772E]/50 rounded-xl p-3 text-sm font-bold text-[#333333] placeholder-gray-400 focus:outline-none transition-colors" />
              <span v-if="errors.fullName" class="text-xs text-red-500 font-bold">{{ errors.fullName }}</span>
            </div>

            <!-- Phone -->
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-bold text-[#666666] uppercase tracking-wider">{{ $t('customer.profile.phone') }} <span class="text-red-500">*</span></label>
              <input v-model="form.phone"
                     type="tel"
                     :placeholder="$t('customer.profile.phonePlaceholder')"
                     class="w-full bg-gray-50 border border-gray-200 focus:border-[#E8772E]/50 rounded-xl p-3 text-sm font-bold text-[#333333] placeholder-gray-400 focus:outline-none transition-colors" />
              <span v-if="errors.phone" class="text-xs text-red-500 font-bold">{{ errors.phone }}</span>
            </div>

            <!-- Email -->
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-bold text-[#666666] uppercase tracking-wider">{{ $t('customer.profile.email') }}</label>
              <input v-model="form.email"
                     type="email"
                     :placeholder="$t('customer.profile.emailPlaceholder')"
                     class="w-full bg-gray-50 border border-gray-200 focus:border-[#E8772E]/50 rounded-xl p-3 text-sm font-bold text-[#333333] placeholder-gray-400 focus:outline-none transition-colors" />
              <span v-if="errors.email" class="text-xs text-red-500 font-bold">{{ errors.email }}</span>
            </div>

            <!-- Date of Birth -->
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-bold text-[#666666] uppercase tracking-wider">{{ $t('customer.profile.dateOfBirth') }}</label>
              <input v-model="form.dateOfBirth"
                     type="date"
                     class="w-full bg-gray-50 border border-gray-200 focus:border-[#E8772E]/50 rounded-xl p-3 text-sm font-bold text-[#333333] focus:outline-none transition-colors" />
            </div>
          </div>

          <!-- Section Divider -->
          <div class="flex items-center gap-3 py-2">
            <div class="flex-1 h-px bg-gray-200"></div>
            <span class="text-[10px] font-black text-gray-400 uppercase tracking-wider whitespace-nowrap">{{ $t('customer.profile.taxInfo') }}</span>
            <div class="flex-1 h-px bg-gray-200"></div>
          </div>

          <!-- Section 2: Tax Invoice Info -->
          <div class="flex flex-col gap-4">
            <!-- Tax Code -->
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-bold text-[#666666] uppercase tracking-wider">{{ $t('customer.profile.taxCode') }}</label>
              <input v-model="form.taxCode"
                     type="text"
                     :placeholder="$t('customer.profile.taxCodePlaceholder')"
                     class="w-full bg-gray-50 border border-gray-200 focus:border-[#E8772E]/50 rounded-xl p-3 text-sm font-bold text-[#333333] placeholder-gray-400 focus:outline-none transition-colors" />
              <p class="text-[10px] text-gray-400 font-bold">{{ $t('customer.profile.taxCodeHint') }}</p>
              <span v-if="errors.taxCode" class="text-xs text-red-500 font-bold">{{ errors.taxCode }}</span>
            </div>

            <!-- Company Name -->
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-bold text-[#666666] uppercase tracking-wider">{{ $t('customer.profile.companyName') }}</label>
              <input v-model="form.companyName"
                     type="text"
                     :placeholder="$t('customer.profile.companyNamePlaceholder')"
                     class="w-full bg-gray-50 border border-gray-200 focus:border-[#E8772E]/50 rounded-xl p-3 text-sm font-bold text-[#333333] placeholder-gray-400 focus:outline-none transition-colors" />
              <span v-if="errors.companyName" class="text-xs text-red-500 font-bold">{{ errors.companyName }}</span>
            </div>

            <!-- Invoice Address -->
            <div class="flex flex-col gap-1.5">
              <label class="text-xs font-bold text-[#666666] uppercase tracking-wider">{{ $t('customer.profile.invoiceAddress') }}</label>
              <textarea v-model="form.invoiceAddress"
                        rows="2"
                        :placeholder="$t('customer.profile.invoiceAddressPlaceholder')"
                        class="w-full bg-gray-50 border border-gray-200 focus:border-[#E8772E]/50 rounded-xl p-3 text-sm font-bold text-[#333333] placeholder-gray-400 focus:outline-none transition-colors resize-none"></textarea>
              <span v-if="errors.invoiceAddress" class="text-xs text-red-500 font-bold">{{ errors.invoiceAddress }}</span>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="flex justify-end gap-3 shrink-0 pt-4 border-t border-gray-100">
            <button @click="goBack"
                    class="h-11 px-5 rounded-xl border border-gray-200 text-gray-500 hover:text-[#333333] font-bold text-xs transition-colors active:scale-95 bg-gray-50">
              {{ $t('customer.profile.cancel') }}
            </button>
            <button @click="handleSave"
                    :disabled="!isFormValid"
                    class="h-11 px-6 rounded-xl bg-[#E8772E] hover:bg-amber-600 disabled:opacity-50 text-white font-extrabold text-xs tracking-wider uppercase transition-all active:scale-95 shadow-md">
              {{ $t('customer.profile.save') }}
            </button>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue';
import { useRouter } from 'vue-router';
import { useCustomerStore, type CustomerProfileData } from '@/stores/customerStore';
import { useI18nStore } from '@/stores/i18n';

const store = useCustomerStore();
const router = useRouter();
const i18nStore = useI18nStore();

const form = reactive<CustomerProfileData>({
  fullName: '',
  phone: '',
  email: '',
  dateOfBirth: '',
  taxCode: '',
  companyName: '',
  invoiceAddress: '',
});

const errors = ref<Partial<Record<keyof CustomerProfileData, string>>>({});

const avatarInitial = computed(() => {
  const name = form.fullName.trim();
  return name ? name.charAt(0).toUpperCase() : '?';
});

const isFormValid = computed(() => {
  return Object.keys(errors.value).length === 0;
});

function validate(): boolean {
  const e: Partial<Record<keyof CustomerProfileData, string>> = {};

  // Full name: required, min 2 chars
  if (!form.fullName.trim()) {
    e.fullName = i18nStore.t('customer.profile.errorNameMin');
  } else if (form.fullName.trim().length < 2) {
    e.fullName = i18nStore.t('customer.profile.errorNameMin');
  }

  // Phone: required, Vietnamese format (0xxxxxxxxx, 10-11 digits)
  const phoneTrim = form.phone.trim();
  if (!phoneTrim) {
    e.phone = i18nStore.t('customer.profile.errorPhoneFormat');
  } else if (!/^0\d{9,10}$/.test(phoneTrim)) {
    e.phone = i18nStore.t('customer.profile.errorPhoneFormat');
  }

  // Email: optional, valid format
  if (form.email.trim() && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email.trim())) {
    e.email = i18nStore.t('customer.profile.errorEmailFormat');
  }

  // Tax code: optional, 10-13 digits
  const taxTrim = form.taxCode.trim();
  if (taxTrim && !/^\d{10,13}$/.test(taxTrim)) {
    e.taxCode = i18nStore.t('customer.profile.errorTaxCodeFormat');
  }

  // Company name: required if tax code present
  if (taxTrim && !form.companyName.trim()) {
    e.companyName = i18nStore.t('customer.profile.errorCompanyRequired');
  }

  // Invoice address: required if tax code present
  if (taxTrim && !form.invoiceAddress.trim()) {
    e.invoiceAddress = i18nStore.t('customer.profile.errorAddressRequired');
  }

  errors.value = e;
  return Object.keys(e).length === 0;
}

function handleSave() {
  if (!validate()) return;
  store.saveProfile({ ...form });
  router.push({ name: 'CustomerMenu' });
}

function goBack() {
  router.push({ name: 'CustomerMenu' });
}

onMounted(() => {
  store.loadProfile();
  const p = store.customerProfile;
  form.fullName = p.fullName || '';
  form.phone = p.phone || '';
  form.email = p.email || '';
  form.dateOfBirth = p.dateOfBirth || '';
  form.taxCode = p.taxCode || '';
  form.companyName = p.companyName || '';
  form.invoiceAddress = p.invoiceAddress || '';
});
</script>
