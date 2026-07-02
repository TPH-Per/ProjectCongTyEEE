<template>
  <div class="checkout-view p-4 max-w-2xl mx-auto">
    <h1 class="text-2xl font-bold mb-4">POS Checkout</h1>
    <form @submit.prevent="submitCheckout" class="space-y-4">
      <div>
        <label>Order ID</label>
        <input v-model="form.orderId" class="border w-full p-2" required />
      </div>
      <div>
        <label>Payment Method</label>
        <select v-model="form.paymentMethod" class="border w-full p-2">
          <option value="CASH">CASH</option>
          <option value="CARD">CARD</option>
          <option value="ZALOPAY">ZALOPAY</option>
        </select>
      </div>
      <div>
        <label>Voucher Code</label>
        <input v-model="form.voucherCode" class="border w-full p-2" />
      </div>
      <div>
        <label>Points to Redeem</label>
        <input type="number" v-model="form.pointsToRedeem" class="border w-full p-2" />
      </div>
      
      <button :disabled="loading" type="submit" class="w-full bg-green-500 text-white py-2 rounded">
        Complete Checkout
      </button>
      
      <div v-if="error" class="text-red-500 mt-2">{{ error }}</div>
      <div v-if="checkoutResult" class="text-green-600 mt-2">
        Invoice #{{ checkoutResult.invoice_number }} generated! Total: {{ checkoutResult.grand_total }}
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useCheckout } from '@/composables/useCheckout'
import { useBranch } from '@/composables/useBranch'
import { supabase } from '@/lib/supabase'

const { executeCheckout, loading, error, checkoutResult } = useCheckout()
const { activeBranchId } = useBranch()

const form = ref({
  orderId: '',
  paymentMethod: 'CASH',
  voucherCode: '',
  pointsToRedeem: 0
})

const submitCheckout = async () => {
  const { data: userData } = await supabase.auth.getUser()
  await executeCheckout({
    orderId: form.value.orderId,
    paymentMethod: form.value.paymentMethod,
    voucherCode: form.value.voucherCode,
    pointsToRedeem: form.value.pointsToRedeem,
    branchId: activeBranchId.value || "",
    cashierId: userData.user?.id || ''
  })
}
</script>
