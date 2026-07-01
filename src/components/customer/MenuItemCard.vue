<!-- File: src/components/customer/MenuItemCard.vue -->
<template>
  <div class="menu-item-card" @click="handleCardClick">
    <!-- Hình ảnh placeholder -->
    <div class="item-image" :style="{ background: imageGradient }">
      <span class="item-emoji">{{ itemEmoji }}</span>
      <div v-if="item.price === 0" class="badge-free">
        Trong gói
      </div>
    </div>

    <!-- Thông tin món -->
    <div class="item-content">
      <h3 class="item-name">{{ item.name }}</h3>
      <span class="item-unit">{{ item.unit }}</span>
      
      <div class="item-footer">
        <div class="item-price-section">
          <span v-if="item.price === 0" class="price-free">
            0K
          </span>
          <span v-else class="price-paid">
            {{ item.price_display }}
          </span>
        </div>
        
        <!-- Nút + thêm trực tiếp (stopPropagation để không mở modal) -->
        <button 
          class="add-btn" 
          @click.stop="handleQuickAdd"
          :class="{ added: isJustAdded }"
        >
          <span class="add-icon" v-if="!isJustAdded">
            {{ quantityInCart > 0 ? quantityInCart : '+' }}
          </span>
          <span class="check-icon" v-else>✓</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import type { MenuItem } from '@/data/menuData'

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
  emit('click-detail', props.item)
}

// Click nút + thêm nhanh, không mở modal
const handleQuickAdd = () => {
  emit('add', props.item)
  
  // Animation feedback
  isJustAdded.value = true
  setTimeout(() => {
    isJustAdded.value = false
  }, 800)
}
</script>

<style scoped>
.menu-item-card {
  background: #1e1e1e;
  border: 1px solid #333;
  border-radius: 12px;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  flex-direction: column;
}

.menu-item-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
  border-color: #ff9800;
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
  color: #ffffff;
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
  border-top: 1px solid #333;
}

.price-free {
  font-size: 20px;
  font-weight: 700;
  color: #4CAF50;
}

.price-paid {
  font-size: 20px;
  font-weight: 700;
  color: #ff9800;
}

/* Nút thêm nhanh */
.add-btn {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: #ff9800;
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  box-shadow: 0 4px 12px rgba(255, 152, 0, 0.3);
  color: white;
}

.add-btn:hover {
  background: #ffb74d;
  transform: scale(1.1);
  box-shadow: 0 6px 16px rgba(255, 152, 0, 0.4);
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
</style>
