<!-- File: src/components/customer/MenuItemDetailModal.vue -->
<template>
  <Teleport to="body">
    <div v-if="isOpen && item" class="modal-overlay" @click.self="handleBack">
      <div class="modal-container">
        <!-- Header -->
        <div class="modal-header">
          <!-- FIX: Thêm @click handler rõ ràng và type="button" -->
          <button class="btn-back" @click="handleBack" type="button">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="pointer-events: none;">
              <line x1="19" y1="12" x2="5" y2="12"></line>
              <polyline points="12 19 5 12 12 5"></polyline>
            </svg>
          </button>
          
          <!-- FIX: Thêm @click handler và type="button" -->
          <button class="btn-cart" @click="handleGoToCart" type="button">
            {{ $t('customer.itemDetail.cart', { count: cartCount }) }}
          </button>
        </div>

        <!-- Body -->
        <div class="modal-body">
          <!-- Gallery Column -->
          <div class="gallery-column">
            <!-- Ảnh chính -->
            <div class="main-image" :style="{ background: currentGradient }">
              <transition name="fade" mode="out-in">
                <span class="main-emoji" :key="selectedThumb">{{ currentEmoji }}</span>
              </transition>
              <div class="image-counter">
                {{ selectedThumb + 1 }} / {{ thumbnails.length }}
              </div>
            </div>

            <!-- Thumbnails -->
            <div class="thumbnails-row">
              <button
                v-for="(thumb, index) in thumbnails"
                :key="index"
                class="thumbnail"
                :class="{ active: selectedThumb === index }"
                :style="{ background: thumb.gradient }"
                @click="handleSelectThumb(index)"
                type="button"
              >
                <span class="thumb-emoji">{{ thumb.emoji }}</span>
                <span class="thumb-label">{{ thumb.label }}</span>
              </button>
            </div>
          </div>

          <!-- Info Column -->
          <div class="info-column">
            <h1 class="item-name">{{ item.name }}</h1>
            <div class="item-price" :class="{ free: item.price === 0 }">
              {{ item.price === 0 ? $t('customer.itemDetail.inBuffetPackage') : item.price_display }}
            </div>

            <div class="description-box">
              <h3 class="section-label">{{ $t('customer.itemDetail.descriptionLabel') }}</h3>
              <p class="description-text">
                {{ item.description || getDefaultDescription() }}
              </p>
            </div>

            <div class="attributes-row">
              <div class="attr-card">
                <span class="attr-icon">🚫</span>
                <span class="attr-label">{{ $t('customer.itemDetail.allergyLabel') }}</span>
                <span class="attr-value">{{ $t('customer.itemDetail.allergyValue') }}</span>
              </div>
              <div class="attr-card">
                <span class="attr-icon">🔥</span>
                <span class="attr-label">{{ $t('customer.itemDetail.spicinessLabel') }}</span>
                <span class="attr-value highlight">{{ $t('customer.itemDetail.spicinessValue') }}</span>
              </div>
              <div class="attr-card">
                <span class="attr-icon">⏱️</span>
                <span class="attr-label">{{ $t('customer.itemDetail.prepTimeLabel') }}</span>
                <span class="attr-value">{{ $t('customer.itemDetail.prepTimeValue') }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div class="modal-footer">
          <div class="footer-row">
            <div class="quantity-section">
              <label class="section-label">{{ $t('customer.itemDetail.quantityLabel') }}</label>
              <div class="quantity-control">
                <button class="qty-btn" @click="decreaseQty" type="button">-</button>
                <span class="qty-value">{{ quantity }}</span>
                <button class="qty-btn" @click="increaseQty" type="button">+</button>
              </div>
            </div>

            <div class="notes-section">
              <label class="section-label">{{ $t('customer.itemDetail.chefNoteLabel') }}</label>
              <input 
                v-model="chefNote" 
                type="text"
                class="note-input"
                :placeholder="$t('customer.itemDetail.chefNotePlaceholder')"
              />
            </div>
          </div>

          <button class="btn-add-cart" @click="handleAddToCart" type="button">
            {{ $t('customer.itemDetail.addToCart') }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import type { MenuItem } from '@/data/menuData'
import { useI18n } from 'vue-i18n'

const props = defineProps<{
  item: MenuItem | null
  isOpen: boolean
  cartCount: number
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'add', item: MenuItem, quantity: number, note: string): void
  (e: 'go-to-cart'): void
}>()

const { t } = useI18n()

const chefNote = ref('')
const quantity = ref(1)
const selectedThumb = ref(0)

// Helper functions
const getEmojiByName = (name: string): string => {
  const n = name.toLowerCase()
  if (n.includes('wagyu') || n.includes('bò') || n.includes('beef')) return '🥩'
  if (n.includes('sườn')) return '🍖'
  if (n.includes('lưỡi')) return '👅'
  if (n.includes('heo') || n.includes('pork') || n.includes('ba chỉ')) return '🐖'
  if (n.includes('nọng')) return '🐷'
  if (n.includes('gà') || n.includes('chicken')) return '🍗'
  if (n.includes('tôm') || n.includes('shrimp')) return '🦐'
  if (n.includes('cá') || n.includes('fish')) return '🐟'
  if (n.includes('bạch tuộc')) return '🐙'
  if (n.includes('cua') || n.includes('ghẹ')) return '🦀'
  if (n.includes('sò') || n.includes('ốc')) return '🐚'
  if (n.includes('bia') || n.includes('beer')) return '🍺'
  if (n.includes('rượu') || n.includes('wine') || n.includes('sake') || n.includes('soju')) return '🍶'
  if (n.includes('trà') || n.includes('tea')) return '🍵'
  if (n.includes('cà phê') || n.includes('coffee')) return '☕'
  if (n.includes('nước') || n.includes('soda') || n.includes('coca')) return '🥤'
  if (n.includes('sinh tố') || n.includes('smoothie')) return '🍹'
  if (n.includes('cơm') || n.includes('rice')) return '🍚'
  if (n.includes('mì') || n.includes('noodle') || n.includes('udon') || n.includes('ramen')) return '🍜'
  if (n.includes('súp') || n.includes('soup')) return '🥣'
  if (n.includes('rau') || n.includes('salad')) return '🥗'
  if (n.includes('nấm')) return '🍄'
  if (n.includes('trứng')) return '🥚'
  if (n.includes('kem') || n.includes('ice cream')) return '🍦'
  if (n.includes('bánh') || n.includes('cake')) return '🍰'
  if (n.includes('trái cây') || n.includes('fruit')) return '🍉'
  if (n.includes('lẩu') || n.includes('hotpot')) return '🍲'
  return '🍲'
}

const getGradientByName = (name: string): string => {
  const n = name.toLowerCase()
  if (n.includes('wagyu') || n.includes('bò') || n.includes('beef')) 
    return 'linear-gradient(135deg, #8B0000 0%, #DC143C 100%)'
  if (n.includes('heo') || n.includes('pork') || n.includes('ba chỉ')) 
    return 'linear-gradient(135deg, #FFB6C1 0%, #FF69B4 100%)'
  if (n.includes('gà') || n.includes('chicken')) 
    return 'linear-gradient(135deg, #FFA500 0%, #FF8C00 100%)'
  if (n.includes('hải sản') || n.includes('tôm') || n.includes('cá') || n.includes('bạch tuộc') || n.includes('cua') || n.includes('sò')) 
    return 'linear-gradient(135deg, #00CED1 0%, #20B2AA 100%)'
  if (n.includes('rau') || n.includes('salad') || n.includes('nấm')) 
    return 'linear-gradient(135deg, #98FB98 0%, #3CB371 100%)'
  if (n.includes('cơm') || n.includes('rice')) 
    return 'linear-gradient(135deg, #FFF8DC 0%, #F5DEB3 100%)'
  if (n.includes('mì') || n.includes('noodle') || n.includes('udon') || n.includes('ramen')) 
    return 'linear-gradient(135deg, #FFE4B5 0%, #DEB887 100%)'
  if (n.includes('kem') || n.includes('bánh') || n.includes('dessert') || n.includes('tráng miệng')) 
    return 'linear-gradient(135deg, #FFB6C1 0%, #FF69B4 100%)'
  if (n.includes('bia') || n.includes('beer')) 
    return 'linear-gradient(135deg, #FFD700 0%, #FFA500 100%)'
  if (n.includes('rượu') || n.includes('wine') || n.includes('soju') || n.includes('sake')) 
    return 'linear-gradient(135deg, #722F37 0%, #8B0000 100%)'
  if (n.includes('lẩu') || n.includes('hotpot'))
    return 'linear-gradient(135deg, #FF6347 0%, #FF4500 100%)'
  return 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
}

const getDetailEmoji = (name: string): string => {
  if (name.includes('lẩu') || name.includes('soup') || name.includes('súp')) return '🔥'
  if (name.includes('nước') || name.includes('bia') || name.includes('rượu') || name.includes('trà')) return '🍋'
  if (name.includes('kem') || name.includes('bánh') || name.includes('trái cây')) return '🍒'
  return '🔪'
}

const getDetailGradient = (name: string): string => {
  if (name.includes('wagyu') || name.includes('bò') || name.includes('beef')) return 'linear-gradient(135deg, #FF4500 0%, #FF6347 100%)'
  if (name.includes('rau') || name.includes('salad') || name.includes('nấm')) return 'linear-gradient(135deg, #32CD32 0%, #228B22 100%)'
  if (name.includes('cơm') || name.includes('rice')) return 'linear-gradient(135deg, #F5DEB3 0%, #D2B48C 100%)'
  return 'linear-gradient(135deg, #FF6B6B 0%, #FF8E53 100%)'
}

const thumbnails = computed(() => {
  if (!props.item) return []
  const name = props.item.name.toLowerCase()
  const mainEmoji = getEmojiByName(props.item.name)
  const mainGradient = getGradientByName(props.item.name)
  
  return [
    { emoji: mainEmoji, gradient: mainGradient, label: t('customer.itemDetail.overview') },
    { emoji: getDetailEmoji(name), gradient: getDetailGradient(name), label: t('customer.itemDetail.preparation') },
    { emoji: '🌾', gradient: 'linear-gradient(135deg, #8B4513 0%, #A0522D 100%)', label: t('customer.itemDetail.ingredients') },
    { emoji: '👨‍🍳', gradient: 'linear-gradient(135deg, #434343 0%, #000000 100%)', label: t('customer.itemDetail.plating') }
  ]
})

const currentEmoji = computed(() => {
  if (thumbnails.value.length === 0) return '🍲'
  return thumbnails.value[selectedThumb.value]?.emoji || '🍲'
})

const currentGradient = computed(() => {
  if (thumbnails.value.length === 0) return 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
  return thumbnails.value[selectedThumb.value]?.gradient || 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
})

const getDefaultDescription = () => {
  if (!props.item) return ''
  const name = props.item.name.toLowerCase()
  if (name.includes('wagyu') || name.includes('bò') || name.includes('beef'))
    return t('customer.itemDetail.defaultDescBeef')
  if (name.includes('vé') || name.includes('ticket'))
    return t('customer.itemDetail.defaultDescTicket')
  return t('customer.itemDetail.defaultDescGeneric')
}

// FIX: Handler functions rõ ràng
const handleBack = () => {
  console.log('Back button clicked')
  emit('close')
}

const handleGoToCart = () => {
  console.log('Go to cart clicked')
  emit('go-to-cart')
}

const handleSelectThumb = (index: number) => {
  console.log('Thumbnail clicked:', index)
  selectedThumb.value = index
}

const increaseQty = () => {
  quantity.value++
}

const decreaseQty = () => {
  if (quantity.value > 1) quantity.value--
}

const handleAddToCart = () => {
  if (!props.item) return
  console.log('Add to cart clicked:', props.item.name, quantity.value)
  emit('add', props.item, quantity.value, chefNote.value)
}

// Reset state khi mở modal
const resetState = () => {
  chefNote.value = ''
  quantity.value = 1
  selectedThumb.value = 0
}

// Watch isOpen để reset
watch(() => props.isOpen, (newVal) => {
  if (newVal) {
    resetState()
  }
})
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.85);
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.modal-container {
  background: #1a1a1a;
  border-radius: 20px;
  width: 100%;
  max-width: 1000px;
  height: 90vh;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
}

.modal-header {
  height: 60px;
  flex-shrink: 0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 24px;
  background: #0f1419;
  border-bottom: 1px solid #333;
}

/* FIX: Button styles rõ ràng */
.btn-back, .btn-cart {
  position: relative;
  z-index: 10;
  pointer-events: auto;
  padding: 10px 20px;
  border: none;
  border-radius: 20px;
  color: white;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 14px;
}

.btn-back {
  background: #2d2d2d;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  font-size: 20px;
}

.btn-back:hover {
  background: #3d3d3d;
  transform: scale(1.05);
}

.btn-cart {
  background: #ff9800;
}

.btn-cart:hover {
  background: #ffb74d;
  transform: translateY(-2px);
}

.modal-body {
  flex: 1;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  padding: 24px;
  overflow: hidden;
  min-height: 0;
}

.gallery-column {
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-height: 0;
}

.main-image {
  flex: 1;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
  min-height: 0;
}

.main-emoji {
  font-size: min(18vw, 180px);
  filter: drop-shadow(0 8px 16px rgba(0, 0, 0, 0.4));
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease, transform 0.3s ease;
}

.fade-enter-from {
  opacity: 0;
  transform: scale(0.9);
}

.fade-leave-to {
  opacity: 0;
  transform: scale(1.1);
}

.image-counter {
  position: absolute;
  bottom: 12px;
  right: 12px;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
  backdrop-filter: blur(10px);
}

.thumbnails-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
  flex-shrink: 0;
}

/* FIX: Thumbnail button styles */
.thumbnail {
  aspect-ratio: 1;
  border-radius: 12px;
  border: 2px solid transparent;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  transition: all 0.25s ease;
  position: relative;
  overflow: hidden;
  padding: 8px;
}

.thumbnail:hover {
  transform: translateY(-3px) scale(1.05);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.4);
}

.thumbnail.active {
  border-color: #ff9800;
  box-shadow: 0 0 0 3px rgba(255, 152, 0, 0.3);
  transform: translateY(-2px);
}

.thumb-emoji {
  font-size: 32px;
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3));
}

.thumb-label {
  font-size: 10px;
  font-weight: 600;
  color: white;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.8);
  letter-spacing: 0.3px;
}

.info-column {
  display: flex;
  flex-direction: column;
  gap: 16px;
  overflow: hidden;
}

.item-name {
  font-size: 28px;
  font-weight: 700;
  color: white;
  margin: 0;
  line-height: 1.2;
  flex-shrink: 0;
}

.item-price {
  font-size: 24px;
  font-weight: 700;
  color: #ff9800;
  flex-shrink: 0;
}

.item-price.free {
  color: #4CAF50;
}

.description-box {
  background: #2d2d2d;
  border-radius: 12px;
  padding: 16px 20px;
  flex-shrink: 0;
}

.section-label {
  font-size: 11px;
  font-weight: 700;
  color: #888;
  text-transform: uppercase;
  letter-spacing: 1px;
  margin: 0 0 8px 0;
}

.description-text {
  font-size: 14px;
  color: #e0e0e0;
  line-height: 1.5;
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
}

.attributes-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
  flex-shrink: 0;
}

.attr-card {
  background: #2d2d2d;
  border-radius: 12px;
  padding: 14px 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  text-align: center;
}

.attr-icon {
  font-size: 22px;
}

.attr-label {
  font-size: 11px;
  color: #888;
}

.attr-value {
  font-size: 13px;
  font-weight: 600;
  color: white;
}

.attr-value.highlight {
  color: #ff9800;
}

.modal-footer {
  padding: 16px 24px;
  background: #1a1a1a;
  border-top: 1px solid #333;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.footer-row {
  display: grid;
  grid-template-columns: 140px 1fr;
  gap: 16px;
  align-items: end;
}

.quantity-section, .notes-section {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.quantity-control {
  display: flex;
  align-items: center;
  gap: 10px;
  background: #2d2d2d;
  border-radius: 10px;
  padding: 6px;
}

.qty-btn {
  width: 32px;
  height: 32px;
  border-radius: 6px;
  background: #3d3d3d;
  border: none;
  color: white;
  font-size: 18px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.qty-btn:hover {
  background: #4d4d4d;
}

.qty-value {
  font-size: 16px;
  font-weight: 700;
  color: white;
  min-width: 24px;
  text-align: center;
}

.note-input {
  width: 100%;
  background: #2d2d2d;
  border: 1px solid #444;
  border-radius: 10px;
  padding: 10px 14px;
  color: white;
  font-size: 14px;
  font-family: inherit;
}

.note-input:focus {
  outline: none;
  border-color: #ff9800;
}

.note-input::placeholder {
  color: #666;
}

.btn-add-cart {
  width: 100%;
  padding: 16px;
  background: linear-gradient(135deg, #ff9800 0%, #ffb74d 100%);
  border: none;
  border-radius: 12px;
  color: white;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.btn-add-cart:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(255, 152, 0, 0.4);
}

@media (max-width: 768px) {
  .modal-container {
    height: 95vh;
  }
  
  .modal-body {
    grid-template-columns: 1fr;
    gap: 16px;
  }
  
  .main-emoji {
    font-size: 80px;
  }
  
  .attributes-row {
    grid-template-columns: 1fr;
  }
}
</style>
