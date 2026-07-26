<!-- File: src/components/customer/MenuItemCard.vue -->
<template>
  <div class="menu-item-card relative group" @click="handleCardClick">
    <!-- Hết món Overlay (unavailable or sold out) -->
    <div v-if="isUnavailable" class="absolute inset-0 z-10 bg-black/75 backdrop-blur-[3px] flex items-center justify-center rounded-2xl cursor-not-allowed">
      <span class="bg-rose-600/90 text-white font-black px-4 py-2 rounded-full border border-rose-400 shadow-xl rotate-[-10deg] text-xs uppercase tracking-wider">
        {{ $t('customer.menuItem.soldOut') }}
      </span>
    </div>

    <!-- Hình ảnh placeholder -->
    <div class="item-image" :style="{ background: imageGradient }">
      <span class="item-emoji transition-transform duration-300 group-hover:scale-110">{{ itemEmoji }}</span>
      <div v-if="item.price === 0" class="badge-free shadow-lg">
        {{ $t('customer.menuItem.inPackage') }}
      </div>
    </div>

    <!-- Thông tin món -->
    <div class="item-content flex-1 flex flex-col justify-between">
      <div>
        <h3 class="item-name">{{ item.name }}</h3>
        <span class="item-unit">{{ item.unit }}</span>
      </div>
      
      <div class="item-footer mt-auto pt-3 border-t border-white/10 flex justify-between items-center">
        <div class="item-price-section">
          <span v-if="item.price === 0" class="text-lg font-black text-emerald-400">
            0K
          </span>
          <span v-else class="text-lg font-black text-amber-400">
            {{ item.price_display }}
          </span>
        </div>
        
        <!-- Nút + thêm trực tiếp hoặc +/- nếu đã có trong giỏ -->
        <div v-if="quantityInCart > 0" class="flex items-center gap-1.5 bg-[#27272a] rounded-xl p-1 z-20 border border-white/10" @click.stop>
          <button @click.stop="handleUpdateQty(quantityInCart - 1)" class="w-8 h-8 rounded-lg bg-[#3f3f46] hover:bg-rose-900/60 active:scale-95 text-white flex items-center justify-center font-bold text-sm transition-all">-</button>
          <span class="w-6 text-center font-black text-white text-xs">{{ quantityInCart }}</span>
          <button @click.stop="handleUpdateQty(quantityInCart + 1)" class="w-8 h-8 rounded-lg bg-amber-500 hover:bg-amber-400 active:scale-95 text-black flex items-center justify-center font-bold text-sm transition-all">+</button>
        </div>
        <button v-else
          class="add-btn z-20" 
          @click.stop="handleQuickAdd"
          :class="{ added: isJustAdded }"
          :disabled="isUnavailable"
        >
          <span class="add-icon" v-if="!isJustAdded">
            +
          </span>
          <span class="check-icon" v-else>✓</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import type { MenuItem } from '@/types/customer'
import { useCustomerStore } from '@/stores/customerStore'

const props = withDefaults(
  defineProps<{
    item: MenuItem;
    quantityInCart?: number;
  }>(),
  {
    quantityInCart: 0
  }
);

const emit = defineEmits<{
  (e: 'add', item: MenuItem): void
  (e: 'click-detail', item: MenuItem): void
}>()

const isJustAdded = ref(false)

// Combined unavailable state: not available OR sold out
const isUnavailable = computed(() => !props.item.is_available || !!props.item.is_sold_out)

const itemEmoji = computed(() => {
  const name = props.item.name.toLowerCase()
  
  // Thịt bò
  if (name.includes('wagyu') || name.includes('bò') || name.includes('beef')) return '🥩'
  if (name.includes('sườn')) return '🍖'
  if (name.includes('lưỡi')) return '👅'
  
  // Thịt heo
  if (name.includes('heo') || name.includes('pork') || name.includes('ba chỉ')) return '🐖'
  if (name.includes('nọng')) return '🐷'
  
  // Thịt gà
  if (name.includes('gà') || name.includes('chicken')) return '🍗'
  
  // Hải sản
  if (name.includes('tôm') || name.includes('shrimp')) return '🦐'
  if (name.includes('cá') || name.includes('fish')) return '🐟'
  if (name.includes('bạch tuộc')) return '🐙'
  if (name.includes('cua') || name.includes('ghẹ')) return '🦀'
  if (name.includes('sò') || name.includes('ốc')) return '🐚'
  
  // Đồ uống
  if (name.includes('bia') || name.includes('beer')) return '🍺'
  if (name.includes('rượu') || name.includes('wine') || name.includes('sake') || name.includes('soju')) return '🍶'
  if (name.includes('trà') || name.includes('tea')) return '🍵'
  if (name.includes('cà phê') || name.includes('coffee')) return '☕'
  if (name.includes('nước') || name.includes('soda') || name.includes('coca')) return '🥤'
  if (name.includes('sinh tố') || name.includes('smoothie')) return '🍹'
  
  // Cơm & Mì
  if (name.includes('cơm') || name.includes('rice')) return '🍚'
  if (name.includes('mì') || name.includes('noodle') || name.includes('udon') || name.includes('ramen')) return '🍜'
  if (name.includes('súp') || name.includes('soup')) return '🥣'
  
  // Rau củ
  if (name.includes('rau') || name.includes('salad')) return '🥗'
  if (name.includes('nấm')) return '🍄'
  if (name.includes('trứng')) return '🥚'
  
  // Tráng miệng
  if (name.includes('kem') || name.includes('ice cream')) return '🍦'
  if (name.includes('bánh') || name.includes('cake')) return '🍰'
  if (name.includes('trái cây') || name.includes('fruit')) return '🍉'
  
  // Khác
  if (name.includes('lẩu') || name.includes('hotpot')) return '🍲'
  
  return '🍲'
})

const imageGradient = computed(() => {
  const name = props.item.name.toLowerCase()
  if (name.includes('wagyu') || name.includes('bò') || name.includes('beef')) 
    return 'linear-gradient(135deg, #450a0a 0%, #991b1b 100%)'
  if (name.includes('heo') || name.includes('pork') || name.includes('ba chỉ')) 
    return 'linear-gradient(135deg, #831843 0%, #be185d 100%)'
  if (name.includes('gà') || name.includes('chicken')) 
    return 'linear-gradient(135deg, #7c2d12 0%, #c2410c 100%)'
  if (name.includes('hải sản') || name.includes('tôm') || name.includes('cá') || name.includes('bạch tuộc') || name.includes('cua') || name.includes('sò')) 
    return 'linear-gradient(135deg, #134e4a 0%, #0f766e 100%)'
  if (name.includes('rau') || name.includes('salad') || name.includes('nấm')) 
    return 'linear-gradient(135deg, #14532d 0%, #15803d 100%)'
  if (name.includes('cơm') || name.includes('rice')) 
    return 'linear-gradient(135deg, #713f12 0%, #a16207 100%)'
  if (name.includes('mì') || name.includes('noodle') || name.includes('udon') || name.includes('ramen')) 
    return 'linear-gradient(135deg, #78350f 0%, #b45309 100%)'
  if (name.includes('kem') || name.includes('bánh') || name.includes('dessert') || name.includes('tráng miệng')) 
    return 'linear-gradient(135deg, #701a75 0%, #a21caf 100%)'
  if (name.includes('bia') || name.includes('beer')) 
    return 'linear-gradient(135deg, #713f12 0%, #d97706 100%)'
  if (name.includes('rượu') || name.includes('wine') || name.includes('soju') || name.includes('sake')) 
    return 'linear-gradient(135deg, #581c87 0%, #7e22ce 100%)'
  return 'linear-gradient(135deg, #1e1b4b 0%, #3730a3 100%)'
})

// Click vào card mở modal chi tiết
const handleCardClick = () => {
  if (isUnavailable.value) return
  emit('click-detail', props.item)
}

const store = useCustomerStore() // Needed for qty update in-place

// Click nút + thêm nhanh, không mở modal
const handleQuickAdd = () => {
  if (isUnavailable.value) return
  emit('add', props.item)
  
  // Animation feedback
  isJustAdded.value = true
  setTimeout(() => {
    isJustAdded.value = false
  }, 800)
}

const handleUpdateQty = (qty: number) => {
  if (isUnavailable.value) return
  if (qty <= 0) {
    store.removeFromCart(props.item.id)
  } else {
    store.updateCartItem(props.item.id, qty)
  }
}
</script>

<style scoped>
.menu-item-card {
  background: #1e1e24;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 16px;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
  display: flex;
  flex-direction: column;
}

.menu-item-card:hover {
  transform: translateY(-4px);
  background: #27272a;
  border-color: rgba(245, 158, 11, 0.4);
  box-shadow: 0 12px 24px -8px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(245, 158, 11, 0.2);
}

.item-image {
  height: 130px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
}

.item-emoji {
  font-size: 56px;
  filter: drop-shadow(0 6px 12px rgba(0, 0, 0, 0.4));
  animation: float 3.5s ease-in-out infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}

.badge-free {
  position: absolute;
  top: 10px;
  right: 10px;
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  color: white;
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 10px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.item-content {
  padding: 14px 16px 16px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex: 1;
}

.item-name {
  font-size: 14px;
  font-weight: 700;
  color: #f4f4f5;
  margin: 0;
  line-height: 1.35;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: 38px;
}

.item-unit {
  font-size: 11px;
  color: #a1a1aa;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-weight: 600;
}

.item-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: auto;
  padding-top: 10px;
}

/* Nút thêm nhanh */
.add-btn {
  width: 38px;
  height: 38px;
  border-radius: 12px;
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3);
  color: #000000;
  font-weight: 900;
}

.add-btn:hover {
  transform: scale(1.08);
  box-shadow: 0 6px 16px rgba(245, 158, 11, 0.4);
}

.add-btn:active {
  transform: scale(0.95);
}

/* Animation khi vừa thêm */
.add-btn.added {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  color: white;
  animation: pulse-success 0.8s cubic-bezier(0.16, 1, 0.3, 1);
  box-shadow: 0 4px 14px rgba(16, 185, 129, 0.4);
}

@keyframes pulse-success {
  0% { transform: scale(1); }
  50% { transform: scale(1.25); }
  100% { transform: scale(1); }
}

.add-icon {
  font-size: 20px;
  font-weight: 900;
  line-height: 1;
}

.check-icon {
  font-size: 16px;
  font-weight: 900;
}

.add-btn:disabled {
  background: #3f3f46;
  color: #71717a;
  cursor: not-allowed;
  box-shadow: none;
}
.add-btn:disabled:hover {
  transform: none;
}
</style>

