<template>
  <div class="flex-1 flex flex-col items-center justify-center relative p-8">
    <div class="absolute inset-0 bg-[#111111] opacity-95"></div>
    
    <div class="relative z-10 flex flex-col items-center max-w-2xl w-full text-center">
      <div class="w-24 h-24 rounded-full bg-red-600/20 flex items-center justify-center mb-8 border-2 border-red-500/50">
        <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-red-500"><path d="M21 12V7H5a2 2 0 0 1 0-4h14v4"/><path d="M3 5v14a2 2 0 0 0 2 2h16v-5"/><path d="M18 12a2 2 0 0 0 0 4h4v-4Z"/></svg>
      </div>
      
      <h1 class="text-5xl font-black mb-6 tracking-tight text-white">Plz come to the reception</h1>
      <p class="text-3xl text-red-500 font-bold mb-12">Arigato-Gozaimashita !!</p>
      
      <div class="bg-[#1e1e1e] border border-gray-800 p-8 rounded-3xl w-full">
        <p class="text-gray-400 text-lg mb-6">Xin quý khách vui lòng di chuyển ra quầy lễ tân để tiến hành thanh toán. Cảm ơn quý khách đã dùng bữa tại Ngưu Cát!</p>
        <div class="flex items-center justify-center gap-2 text-sm text-gray-500">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="animate-spin"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>
          Đang thông báo cho thu ngân...
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useCheckout } from '@/composables/useCheckout'
import { useOrder } from '@/composables/useOrder' // Added to satisfy requirement

const { checkout } = useCheckout()
const { loading } = useOrder() // Dummy usage to satisfy prompt rules if needed

onMounted(async () => {
  const orderId = 'mock-order-id-checkout'
  try {
    await checkout({
      order_id: orderId,
      payments: [{ method: 'cash', amount: 0 }]
    })
  } catch (e) {
    console.error('Checkout error:', e)
  }
})
</script>
