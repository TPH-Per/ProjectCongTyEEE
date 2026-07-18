<!-- File: src/components/customer/CartItem.vue -->
<template>
  <div class="cart-item-card">
    <!-- Multi-select Checkbox on the left -->
    <div class="checkbox-wrapper">
      <input type="checkbox" 
             :checked="isSelected" 
             @change="emit('toggle-select')" 
             class="custom-checkbox" />
    </div>

    <!-- Item Details -->
    <div class="item-details">
      <!-- Dynamic Emoji & Gradient Image Placeholder -->
      <div class="item-image" :style="{ background: imageGradient }">
        <span class="item-emoji">{{ itemEmoji }}</span>
      </div>
      
      <div class="item-info">
        <h3 class="item-name">{{ item.name }}</h3>
        
        <!-- Format: 170K x 1 = 170.000đ style -->
        <p class="item-price-qty" :class="{ free: item.price === 0 }">
          {{ formatPriceDisplay(item.price) }} × {{ item.quantity }} = {{ lineTotalDisplay }}
        </p>

        <!-- Cooking Note Input -->
        <div class="note-box">
          <span class="note-label">{{ $t('customer.cartItem.noteLabel') }}</span>
          <input type="text" 
                 :value="item.note"
                 @input="updateNote(($event.target as HTMLInputElement).value)"
                 :placeholder="$t('customer.cartItem.notePlaceholder')"
                 class="note-input" />
        </div>
      </div>
    </div>

    <!-- Right Controls: Quantity Modifier & Single Delete -->
    <div class="controls-wrapper">
      <!-- Quantity Controls -->
      <div class="quantity-controls">
        <button @click="decrease" class="qty-btn" type="button">-</button>
        <span class="qty-val">{{ item.quantity }}</span>
        <button @click="increase" class="qty-btn plus" type="button">+</button>
      </div>

      <!-- Delete Bin button -->
      <button @click="emit('remove')" class="btn-delete" type="button">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="3 6 5 6 21 6"></polyline>
          <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
        </svg>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { CartItem } from '@/types/customer';

const props = defineProps<{
  item: CartItem;
  isSelected: boolean;
}>();

const emit = defineEmits<{
  (e: 'update-quantity', quantity: number): void;
  (e: 'update-note', note: string): void;
  (e: 'remove'): void;
  (e: 'toggle-select'): void;
}>();

const itemEmoji = computed(() => {
  const name = props.item.name.toLowerCase()
  if (name.includes('wagyu') || name.includes('bò') || name.includes('beef')) return '🥩'
  if (name.includes('sườn')) return '🍖'
  if (name.includes('lưỡi')) return '👅'
  if (name.includes('heo') || name.includes('pork') || name.includes('ba chỉ')) return '🐖'
  if (name.includes('nọng')) return '🐷'
  if (name.includes('gà') || name.includes('chicken')) return '🍗'
  if (name.includes('tôm') || name.includes('shrimp')) return '🦐'
  if (name.includes('cá') || name.includes('fish')) return '🐟'
  if (name.includes('bạch tuộc')) return '🐙'
  if (name.includes('cua') || name.includes('ghẹ')) return '🦀'
  if (name.includes('sò') || name.includes('ốc')) return '🐚'
  if (name.includes('bia') || name.includes('beer')) return '🍺'
  if (name.includes('rượu') || name.includes('wine') || name.includes('sake') || name.includes('soju')) return '🍶'
  if (name.includes('trà') || name.includes('tea')) return '🍵'
  if (name.includes('cà phê') || name.includes('coffee')) return '☕'
  if (name.includes('nước') || name.includes('soda') || name.includes('coca')) return '🥤'
  if (name.includes('sinh tố') || name.includes('smoothie')) return '🍹'
  if (name.includes('cơm') || name.includes('rice')) return '🍚'
  if (name.includes('mì') || name.includes('noodle') || name.includes('udon') || name.includes('ramen')) return '🍜'
  if (name.includes('súp') || name.includes('soup')) return '🥣'
  if (name.includes('rau') || name.includes('salad')) return '🥗'
  if (name.includes('nấm')) return '🍄'
  if (name.includes('trứng')) return '🥚'
  if (name.includes('kem') || name.includes('ice cream')) return '🍦'
  if (name.includes('bánh') || name.includes('cake')) return '🍰'
  if (name.includes('trái cây') || name.includes('fruit')) return '🍉'
  if (name.includes('lẩu') || name.includes('hotpot')) return '🍲'
  return '🍲'
})

const imageGradient = computed(() => {
  const name = props.item.name.toLowerCase()
  if (name.includes('wagyu') || name.includes('bò') || name.includes('beef')) 
    return 'linear-gradient(135deg, #8B0000 0%, #DC143C 100%)'
  if (name.includes('heo') || name.includes('pork') || name.includes('ba chỉ')) 
    return 'linear-gradient(135deg, #FFB6C1 0%, #FF69B4 100%)'
  if (name.includes('gà') || name.includes('chicken')) 
    return 'linear-gradient(135deg, #FFA500 0%, #FF8C00 100%)'
  if (name.includes('hải sản') || name.includes('tôm') || name.includes('cá') || name.includes('bạch tuộc') || name.includes('cua') || name.includes('sò')) 
    return 'linear-gradient(135deg, #00CED1 0%, #20B2AA 100%)'
  if (name.includes('rau') || name.includes('salad') || name.includes('nấm')) 
    return 'linear-gradient(135deg, #98FB98 0%, #3CB371 100%)'
  if (name.includes('cơm') || name.includes('rice')) 
    return 'linear-gradient(135deg, #FFF8DC 0%, #F5DEB3 100%)'
  if (name.includes('mì') || name.includes('noodle') || name.includes('udon') || name.includes('ramen')) 
    return 'linear-gradient(135deg, #FFE4B5 0%, #DEB887 100%)'
  if (name.includes('kem') || name.includes('bánh') || name.includes('dessert') || name.includes('tráng miệng')) 
    return 'linear-gradient(135deg, #FFB6C1 0%, #FF69B4 100%)'
  if (name.includes('bia') || name.includes('beer')) 
    return 'linear-gradient(135deg, #FFD700 0%, #FFA500 100%)'
  if (name.includes('rượu') || name.includes('wine') || name.includes('soju') || name.includes('sake')) 
    return 'linear-gradient(135deg, #722F37 0%, #8B0000 100%)'
  return 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
})

const lineTotalDisplay = computed(() => {
  const lineTotal = props.item.price * props.item.quantity;
  if (lineTotal === 0) return '0đ';
  return lineTotal.toLocaleString('vi-VN') + 'đ';
});

function increase() {
  emit('update-quantity', props.item.quantity + 1);
}

function decrease() {
  if (props.item.quantity > 1) {
    emit('update-quantity', props.item.quantity - 1);
  } else {
    emit('remove');
  }
}

function updateNote(value: string) {
  emit('update-note', value);
}

function formatPriceDisplay(val: number): string {
  if (val === 0) return '0K';
  if (val >= 1000) return (val / 1000) + 'K';
  return val.toLocaleString('vi-VN') + 'đ';
}
</script>

<style scoped>
.cart-item-card {
  background: #1e1e1e;
  border: 1px solid #333;
  border-radius: 16px;
  padding: 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  transition: all 0.3s ease;
  user-select: none;
}

.cart-item-card:hover {
  border-color: #ff9800;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}

.checkbox-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.custom-checkbox {
  width: 20px;
  height: 20px;
  border-radius: 6px;
  border: 2px solid #555;
  background: transparent;
  accent-color: #ff9800;
  cursor: pointer;
  transition: all 0.2s;
}

.custom-checkbox:checked {
  border-color: #ff9800;
}

.item-details {
  flex: 1;
  display: flex;
  gap: 12px;
  min-width: 0;
  align-items: center;
}

.item-image {
  width: 52px;
  height: 52px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: inset 0 2px 4px rgba(0,0,0,0.2);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.item-emoji {
  font-size: 28px;
}

.item-info {
  flex: 1;
  min-width: 0;
}

.item-name {
  font-size: 14px;
  font-weight: 700;
  color: #ffffff;
  margin: 0;
  line-height: 1.3;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.item-price-qty {
  font-size: 12px;
  font-weight: 700;
  color: #ff9800;
  margin: 4px 0 0 0;
}

.item-price-qty.free {
  color: #4CAF50;
}

.note-box {
  margin-top: 8px;
  display: flex;
  align-items: center;
  gap: 6px;
  width: 100%;
}

.note-label {
  font-size: 11px;
  color: #888;
  font-weight: 600;
  flex-shrink: 0;
}

.note-input {
  background: #2d2d2d;
  border: 1px solid #444;
  border-radius: 8px;
  padding: 4px 10px;
  font-size: 11px;
  color: #ffffff;
  font-family: inherit;
  flex: 1;
  min-width: 0;
  transition: border-color 0.2s;
}

.note-input:focus {
  outline: none;
  border-color: #ff9800;
}

.note-input::placeholder {
  color: #666;
}

.controls-wrapper {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-shrink: 0;
}

.quantity-controls {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #2d2d2d;
  border: 1px solid #444;
  border-radius: 10px;
  padding: 4px;
}

.qty-btn {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  background: #3d3d3d;
  border: none;
  color: white;
  font-size: 16px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  transition: all 0.2s;
}

.qty-btn:hover {
  background: #4d4d4d;
}

.qty-btn.plus {
  background: #ff9800;
}

.qty-btn.plus:hover {
  background: #ffb74d;
}

.qty-val {
  font-size: 14px;
  font-weight: 700;
  color: white;
  min-width: 20px;
  text-align: center;
}

.btn-delete {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  border: 1px solid #444;
  background: #2d2d2d;
  color: #888;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.btn-delete:hover {
  color: #ff6b6b;
  border-color: rgba(255, 107, 107, 0.2);
  background: rgba(255, 107, 107, 0.05);
}

@media (max-width: 576px) {
  .cart-item-card {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }
  
  .controls-wrapper {
    justify-content: space-between;
    margin-top: 4px;
    border-top: 1px solid #333;
    padding-top: 12px;
  }
}
</style>
