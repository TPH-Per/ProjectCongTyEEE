<!-- File: src/components/customer/BottomCartBar.vue -->
<template>
  <transition name="slide-up">
    <div v-if="cartItemCount > 0" class="bottom-cart-bar">
      <div class="cart-info">
        <div class="cart-icon-wrapper">
          🛒
        </div>
        <div class="cart-text">
          <h4 class="cart-title">Giỏ hàng của bàn</h4>
          <p class="cart-summary">
            Đã chọn <span class="highlight">{{ cartItemCount }} món</span> · Tổng cộng: <span class="highlight-price">{{ cartTotalDisplay }}</span>
          </p>
        </div>
      </div>

      <button @click="emit('go-to-cart')" class="btn-go-cart">
        Xem giỏ hàng
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
          <line x1="5" y1="12" x2="19" y2="12"></line>
          <polyline points="12 5 19 12 12 19"></polyline>
        </svg>
      </button>
    </div>
  </transition>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  cartItemCount: number
  cartTotal: number
}>()

const emit = defineEmits<{
  (e: 'go-to-cart'): void
}>()

const cartTotalDisplay = computed(() => {
  return props.cartTotal.toLocaleString('vi-VN') + 'đ'
})
</script>

<style scoped>
.bottom-cart-bar {
  background: #1e1e1e;
  border-top: 1px solid #333;
  padding: 12px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: 0 -10px 25px rgba(0,0,0,0.5);
  height: 70px;
  box-sizing: border-box;
  pointer-events: auto; /* Enable click/touch events inside fixed-bottom-container */
}

.cart-info {
  display: flex;
  align-items: center;
  gap: 16px;
}

.cart-icon-wrapper {
  width: 44px;
  height: 44px;
  background: rgba(255, 152, 0, 0.1);
  border: 1px solid rgba(255, 152, 0, 0.2);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
}

.cart-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.cart-title {
  font-size: 14px;
  font-weight: 700;
  color: white;
  margin: 0;
}

.cart-summary {
  font-size: 12px;
  font-weight: 600;
  color: #a0a0a0;
  margin: 0;
}

.highlight {
  color: #ff9800;
  font-weight: 800;
}

.highlight-price {
  color: #ff9800;
  font-weight: 800;
}

.btn-go-cart {
  background: #ff9800;
  border: none;
  border-radius: 12px;
  color: white;
  font-size: 14px;
  font-weight: 800;
  padding: 12px 24px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s;
  box-shadow: 0 4px 12px rgba(255, 152, 0, 0.2);
}

.btn-go-cart:hover {
  background: #e68a00;
  transform: translateY(-1px);
}

.btn-go-cart:active {
  transform: translateY(0);
}

/* Slide up animation */
.slide-up-enter-active, .slide-up-leave-active {
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}
.slide-up-enter-from, .slide-up-leave-to {
  transform: translateY(100%);
  opacity: 0;
}
</style>
