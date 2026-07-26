<template>
  <div class="flex flex-col items-center w-full max-w-4xl space-y-6">
    <div class="text-center">
      <h2 class="text-2xl font-bold text-white mb-2">{{ $t('customer.setup.selectServiceMode') }}</h2>
      <p class="text-gray-400">{{ $t('customer.setup.selectServiceModeDesc') }}</p>
    </div>

    <!-- Mode Selector -->
    <div class="flex p-1 bg-gray-900 rounded-xl border border-gray-800 w-full max-w-md">
      <button type="button" @click="serviceMode = 'alacarte'; selectedPackageId = null"
              :class="['flex-1 py-3 text-sm font-bold rounded-lg transition-all', serviceMode === 'alacarte' ? 'bg-amber-500 text-white shadow-lg' : 'text-gray-400 hover:text-white']">
        {{ $t('customer.setup.alacarte') }}
      </button>
      <button type="button" @click="serviceMode = 'buffet'"
              :class="['flex-1 py-3 text-sm font-bold rounded-lg transition-all', serviceMode === 'buffet' ? 'bg-amber-500 text-white shadow-lg' : 'text-gray-400 hover:text-white']">
        {{ $t('customer.setup.buffet') }}
      </button>
    </div>

    <!-- Package List -->
    <div v-if="serviceMode === 'buffet'" class="grid grid-cols-1 md:grid-cols-2 gap-4 w-full transition-all">
      <div v-for="pkg in packages" :key="pkg.id"
           @click="selectedPackageId = pkg.id"
           :class="[ 
             'relative p-6 rounded-2xl border-2 cursor-pointer transition-all',
             selectedPackageId === pkg.id 
               ? 'border-amber-500 bg-amber-500/10' 
               : 'border-gray-800 bg-gray-900 hover:border-gray-700'
           ]">
        <div v-if="selectedPackageId === pkg.id" class="absolute top-4 right-4 text-amber-500">
          <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
          </svg>
        </div>
        <h3 class="text-xl font-bold text-white mb-4">{{ pkg.name }}</h3>
        <div class="space-y-2">
          <div class="flex justify-between text-sm">
            <span class="text-gray-400">{{ $t('customer.setup.adult') }}</span>
            <span class="font-medium text-amber-500">{{ formatPrice(pkg.priceAdult) }}</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-400">{{ $t('customer.setup.child') }}</span>
            <span class="font-medium text-amber-500">{{ formatPrice(pkg.priceChild) }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Guest Count -->
    <div class="flex flex-col items-center w-full mt-8 bg-gray-900 p-6 rounded-2xl border border-gray-800">
      <div class="text-amber-500 text-sm font-medium mb-4 flex items-center gap-2">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
        {{ $t('customer.setup.tableCapacity', { capacity: tableCapacity }) }}
      </div>
      
      <div class="flex gap-8 w-full justify-center">
        <!-- Adult -->
        <div class="flex flex-col items-center space-y-3">
          <label class="text-gray-400 font-medium">{{ $t('customer.setup.adultCount') }}</label>
          <div class="flex items-center gap-4">
            <button type="button" @click="adultCount = Math.max(1, adultCount - 1)"
                    class="w-12 h-12 rounded-full bg-gray-800 text-white flex items-center justify-center hover:bg-gray-700 active:scale-95 transition-transform text-2xl font-bold disabled:opacity-50"
                    :disabled="adultCount <= 1">
              -
            </button>
            <span class="text-3xl font-bold text-white w-12 text-center">{{ adultCount }}</span>
            <button type="button" @click="(adultCount + childCount < tableCapacity) && adultCount++"
                    class="w-12 h-12 rounded-full bg-gray-800 text-white flex items-center justify-center hover:bg-gray-700 active:scale-95 transition-transform text-2xl font-bold disabled:opacity-50"
                    :disabled="adultCount + childCount >= tableCapacity">
              +
            </button>
          </div>
        </div>
        
        <!-- Child -->
        <div class="flex flex-col items-center space-y-3 border-l border-gray-800 pl-8">
          <label class="text-gray-400 font-medium">{{ $t('customer.setup.childCount') }}</label>
          <div class="flex items-center gap-4">
            <button type="button" @click="childCount = Math.max(0, childCount - 1)"
                    class="w-12 h-12 rounded-full bg-gray-800 text-white flex items-center justify-center hover:bg-gray-700 active:scale-95 transition-transform text-2xl font-bold disabled:opacity-50"
                    :disabled="childCount <= 0">
              -
            </button>
            <span class="text-3xl font-bold text-white w-12 text-center">{{ childCount }}</span>
            <button type="button" @click="(adultCount + childCount < tableCapacity) && childCount++"
                    class="w-12 h-12 rounded-full bg-gray-800 text-white flex items-center justify-center hover:bg-gray-700 active:scale-95 transition-transform text-2xl font-bold disabled:opacity-50"
                    :disabled="adultCount + childCount >= tableCapacity">
              +
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Actions -->
    <div class="flex gap-4 w-full justify-center pt-4">
      <button type="button" @click="$emit('back')"
              class="px-8 py-4 rounded-xl font-bold text-gray-400 bg-gray-900 border border-gray-800 hover:text-white hover:border-gray-700 transition-all active:scale-95">
        {{ $t('common.back') }}
      </button>
      <button type="button" @click="confirm"
              :disabled="serviceMode === 'buffet' && !selectedPackageId"
              class="px-8 py-4 rounded-xl font-bold text-white bg-amber-600 hover:bg-amber-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all active:scale-95 min-w-[200px]">
        {{ $t('common.confirm') }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const props = defineProps<{
  packages: any[];
  tableCapacity: number;
}>();

const emit = defineEmits<{
  (e: 'select', data: { packageId: string | null; serviceMode: 'alacarte' | 'buffet'; adultCount: number; childCount: number }): void;
  (e: 'back'): void;
}>();

const serviceMode = ref<'alacarte' | 'buffet'>('alacarte');
const selectedPackageId = ref<string | null>(null);
const adultCount = ref(2);
const childCount = ref(0);

function formatPrice(price: number): string {
  return price.toLocaleString('vi-VN') + 'đ';
}

function confirm() {
  if (serviceMode.value === 'alacarte' || selectedPackageId.value) {
    emit('select', {
      packageId: serviceMode.value === 'alacarte' ? null : selectedPackageId.value,
      serviceMode: serviceMode.value,
      adultCount: adultCount.value,
      childCount: childCount.value
    });
  }
}
</script>
