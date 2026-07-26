<!-- File: src/components/customer/MenuItemCard.vue -->
<template>
  <div class="menu-item-card relative" @click="handleCardClick">
    <!-- Hết món Overlay -->
    <div v-if="!item.is_available" class="absolute inset-0 z-10 bg-black/60 backdrop-blur-[2px] flex items-center justify-center rounded-xl cursor-not-allowed">
      <span class="bg-red-600/90 text-white font-bold px-4 py-2 rounded-full border border-red-400 shadow-lg rotate-[-10deg]">{{ $t('customer.menuItem.soldOut') }}</span>
    </div>

    <!-- Hình ảnh placeholder -->
    <div class="item-image" :style="{ background: imageGradient }">
      <span class="item-emoji">{{ itemEmoji }}</span>
      <div v-if="item.price === 0" class="badge-free shadow-md">
        {{ $t('customer.menuItem.inPackage') }}
      </div>
    </div>

    <!-- Thông tin món -->
    <div class="item-content flex-1 flex flex-col justify-between">
      <div>
        <h3 class="item-name">{{ item.name }}</h3>
        <span class="item-unit">{{ item.unit }}</span>
      </div>
      
      <div class="item-footer mt-auto pt-3 border-t border-gray-200 flex justify-between items-center">
        <div class="item-price-section">
          <span v-if="item.price === 0" class="text-xl font-bold text-[#4CAF50]">
            0K
          </span>
          <span v-else class="text-xl font-bold text-[#C62828]">
            {{ item.price_display }}
          </span>
        </div>
        
        <!-- Nút + thêm trực tiếp hoặc +/- nếu đã có trong giỏ -->
        <div v-if="quantityInCart > 0" class="flex items-center gap-2 bg-gray-100 rounded-xl p-1 z-20 border border-gray-200" @click.stop>
          <button @click.stop="handleUpdateQty(quantityInCart - 1)" class="w-11 h-11 rounded-lg bg-white active:bg-gray-200 text-[#333] flex items-center justify-center font-bold text-lg shadow-sm transition-colors">-</button>
          <span class="w-8 text-center font-bold text-[#333]">{{ quantityInCart }}</span>
          <button @click.stop="handleUpdateQty(quantityInCart + 1)" class="w-11 h-11 rounded-lg bg-[#E8772E] active:bg-[#C96626] text-white flex items-center justify-center font-bold text-lg shadow-sm transition-colors">+</button>
        </div>
        <button v-else
          class="add-btn z-20" 
          @click.stop="handleQuickAdd"
          :class="{ added: isJustAdded }"
          :disabled="!item.is_available"
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

// Click vào card mở modal chi tiết
const handleCardClick = () => {
  if (!props.item.is_available) return
  emit('click-detail', props.item)
}

const store = useCustomerStore() // Needed for qty update in-place

// Click nút + thêm nhanh, không mở modal
const handleQuickAdd = () => {
  if (!props.item.is_available) return
  emit('add', props.item)
  
  // Animation feedback
  isJustAdded.value = true
  setTimeout(() => {
    isJustAdded.value = false
  }, 800)
}

const handleUpdateQty = (qty: number) => {
  if (!props.item.is_available) return
  if (qty <= 0) {
    store.removeFromCart(props.item.id)
  } else {
    store.updateCartItem(props.item.id, qty)
  }
}
</script>

<style scoped>
.menu-item-card {
  background: #ffffff;
  border: 1px solid #eeeeee;
  border-radius: 12px;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  flex-direction: column;
}

.menu-item-card:active {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  border-color: #E8772E;
}

.item-image {
  height: 140px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
}

.item-emoji {
  font-size: 64px;
  filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.3));
  animation: float 3s ease-in-out infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}

.badge-free {
  position: absolute;
  top: 10px;
  right: 10px;
  background: #4CAF50;
  color: white;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.item-content {
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex: 1;
}

.item-name {
  font-size: 15px;
  font-weight: 600;
  color: #333333;
  margin: 0;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: 42px;
}

.item-unit {
  font-size: 12px;
  color: #888;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.item-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: auto;
  padding-top: 12px;
  border-top: 1px solid #eee;
}



/* Nút thêm nhanh */
.add-btn {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: #E8772E;
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.1s;
  box-shadow: 0 4px 12px rgba(232, 119, 46, 0.3);
  color: white;
}

.add-btn:active {
  background: #C96626;
  transform: scale(0.95);
  box-shadow: 0 2px 8px rgba(232, 119, 46, 0.4);
}

/* Animation khi vừa thêm */
.add-btn.added {
  background: #4CAF50;
  animation: pulse-success 0.8s ease;
  box-shadow: 0 4px 12px rgba(76, 175, 80, 0.4);
}

@keyframes pulse-success {
  0% { transform: scale(1); }
  50% { transform: scale(1.3); }
  100% { transform: scale(1); }
}

.add-icon {
  font-size: 16px;
  color: white;
  font-weight: 700;
}

.check-icon {
  font-size: 20px;
  color: white;
  font-weight: 700;
}

.add-btn:disabled {
  background: #555;
  cursor: not-allowed;
  box-shadow: none;
}
.add-btn:disabled:hover {
  transform: none;
}
</style>
