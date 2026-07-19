<template>
  <div v-if="cartCount > 0" class="cart-bar">
    <div class="cart-info">
      <span class="cart-icon">🛒</span>
      <span class="cart-text">
        {{ $t('customer.cartBar.text') }}
      </span>
      <span class="cart-divider">|</span>
      <span class="cart-count">
        {{ $t('customer.cartBar.items', { count: cartCount }) }}
      </span>
      <span class="cart-divider">|</span>
      <span class="cart-total">
        {{ $t('customer.cartBar.total') }} {{ formatTotal }}
      </span>
    </div>
    
    <button class="btn-view-cart" @click="handleViewCart">
      {{ $t('customer.cartBar.viewCart') }}
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
  position: fixed;
  bottom: 70px; /* Nằm trên Bottom Tabs (60px) */
  left: 260px; /* Bằng width sidebar */
  right: 0;
  background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
  border-top: 1px solid #444;
  padding: 12px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  z-index: 101; /* Cao hơn Bottom Tabs (100) */
  box-shadow: 0 -4px 12px rgba(0, 0, 0, 0.3);
  backdrop-filter: blur(10px);
  pointer-events: auto; /* Cho phép nhận sự kiện click/chạm khi nằm trong container */
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
  font-size: 14px;
  font-weight: 500;
  color: #e0e0e0;
}

.cart-divider {
  color: #666;
  font-size: 14px;
}

.cart-count {
  font-size: 14px;
  font-weight: 600;
  color: #ff9800;
}

.cart-total {
  font-size: 14px;
  font-weight: 700;
  color: #4CAF50;
}

.btn-view-cart {
  padding: 10px 20px;
  background: linear-gradient(135deg, #ff9800 0%, #ffb74d 100%);
  border: none;
  border-radius: 8px;
  color: white;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 6px;
}

.btn-view-cart:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(255, 152, 0, 0.4);
}

/* Responsive */
@media (max-width: 768px) {
  .cart-bar {
    left: 200px; /* Sidebar width trên mobile */
    padding: 10px 16px;
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
