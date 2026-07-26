<template>
  <div v-if="cartCount > 0" class="cart-bar">
    <div class="cart-info">
      <span class="cart-icon">🛒</span>
      <span class="cart-text font-bold">
        {{ $t('customer.cartBar.text') }}
      </span>
      <span class="cart-divider">|</span>
      <span class="cart-count font-black text-amber-400">
        {{ $t('customer.cartBar.items', { count: cartCount }) }}
      </span>
      <span class="cart-divider">|</span>
      <span class="cart-total font-black text-emerald-400">
        {{ $t('customer.cartBar.total') }} {{ formatTotal }}
      </span>
    </div>
    
    <button class="btn-view-cart" @click="handleViewCart">
      <span>{{ $t('customer.cartBar.viewCart') }}</span>
      <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <line x1="5" y1="12" x2="19" y2="12"></line>
        <polyline points="12 5 19 12 12 19"></polyline>
      </svg>
    </button>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  cartCount: number
  cartTotal: number
}>()

const emit = defineEmits<{
  (e: 'view-cart'): void
}>()

const formatTotal = computed(() => {
  const total = props.cartTotal
  if (total === 0) return '0đ'
  if (total >= 1000000) {
    return `${(total / 1000000).toFixed(1)}M`
  }
  return `${(total / 1000).toFixed(0)}K`
})

const handleViewCart = () => {
  emit('view-cart')
}
</script>

<style scoped>
.cart-bar {
  width: 100%;
  position: relative;
  background: linear-gradient(135deg, #141417 0%, #1e1e24 100%);
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
  padding: 14px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: 0 -8px 24px rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(16px);
  pointer-events: auto;
  z-index: 20;
}

.cart-info {
  display: flex;
  align-items: center;
  gap: 12px;
  color: white;
}

.cart-icon {
  font-size: 20px;
}

.cart-text {
  font-size: 13px;
  color: #e4e4e7;
}

.cart-divider {
  color: rgba(255, 255, 255, 0.2);
  font-size: 13px;
}

.cart-count {
  font-size: 14px;
}

.cart-total {
  font-size: 14px;
}

.btn-view-cart {
  padding: 10px 22px;
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  border: none;
  border-radius: 12px;
  color: #000000;
  font-size: 13px;
  font-weight: 800;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  display: flex;
  align-items: center;
  gap: 6px;
  box-shadow: 0 4px 14px rgba(245, 158, 11, 0.3);
}

.btn-view-cart:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(245, 158, 11, 0.45);
}

.btn-view-cart:active {
  transform: scale(0.96);
}

/* Responsive */
@media (max-width: 768px) {
  .cart-bar {
    padding: 12px 16px;
  }
  
  .cart-text {
    font-size: 12px;
  }
  
  .cart-count, .cart-total {
    font-size: 12px;
  }
  
  .btn-view-cart {
    padding: 8px 16px;
    font-size: 12px;
  }
}
</style>

