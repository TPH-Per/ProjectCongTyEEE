<!-- File: src/components/customer/MenuItemDetailModal.vue -->
<template>
  <Teleport to="body">
    <div v-if="isOpen && item" class="modal-overlay" @click.self="handleBack">
      <div class="modal-container">
        <!-- Header -->
        <div class="modal-header">
          <button class="btn-back" @click="handleBack" type="button">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="pointer-events: none;">
              <line x1="19" y1="12" x2="5" y2="12"></line>
              <polyline points="12 19 5 12 12 5"></polyline>
            </svg>
          </button>
          
          <button class="btn-cart" @click="handleGoToCart" type="button">
            {{ $t('customer.itemDetail.cart', { count: cartCount }) }}
          </button>
        </div>

        <!-- Body -->
        <div class="modal-body scrollbar-hide">
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
                maxlength="100"
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
import { useI18nStore } from '@/stores/i18n'

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

const i18nStore = useI18nStore()
const t = i18nStore.t

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
    return 'linear-gradient(135deg, #450a0a 0%, #991b1b 100%)'
  if (n.includes('heo') || n.includes('pork') || n.includes('ba chỉ')) 
    return 'linear-gradient(135deg, #831843 0%, #be185d 100%)'
  if (n.includes('gà') || n.includes('chicken')) 
    return 'linear-gradient(135deg, #7c2d12 0%, #c2410c 100%)'
  if (n.includes('hải sản') || n.includes('tôm') || n.includes('cá') || n.includes('bạch tuộc') || n.includes('cua') || n.includes('sò')) 
    return 'linear-gradient(135deg, #134e4a 0%, #0f766e 100%)'
  if (n.includes('rau') || n.includes('salad') || n.includes('nấm')) 
    return 'linear-gradient(135deg, #14532d 0%, #15803d 100%)'
  if (n.includes('cơm') || n.includes('rice')) 
    return 'linear-gradient(135deg, #713f12 0%, #a16207 100%)'
  if (n.includes('mì') || n.includes('noodle') || n.includes('udon') || n.includes('ramen')) 
    return 'linear-gradient(135deg, #78350f 0%, #b45309 100%)'
  if (n.includes('kem') || n.includes('bánh') || n.includes('dessert') || n.includes('tráng miệng')) 
    return 'linear-gradient(135deg, #701a75 0%, #a21caf 100%)'
  if (n.includes('bia') || n.includes('beer')) 
    return 'linear-gradient(135deg, #713f12 0%, #d97706 100%)'
  if (n.includes('rượu') || n.includes('wine') || n.includes('soju') || n.includes('sake')) 
    return 'linear-gradient(135deg, #581c87 0%, #7e22ce 100%)'
  if (n.includes('lẩu') || n.includes('hotpot'))
    return 'linear-gradient(135deg, #9a3412 0%, #c2410c 100%)'
  return 'linear-gradient(135deg, #1e1b4b 0%, #3730a3 100%)'
}

const getDetailEmoji = (name: string): string => {
  if (name.includes('lẩu') || name.includes('soup') || name.includes('súp')) return '🔥'
  if (name.includes('nước') || name.includes('bia') || name.includes('rượu') || name.includes('trà')) return '🍋'
  if (name.includes('kem') || name.includes('bánh') || name.includes('trái cây')) return '🍒'
  return '🔪'
}

const getDetailGradient = (name: string): string => {
  if (name.includes('wagyu') || name.includes('bò') || name.includes('beef')) return 'linear-gradient(135deg, #7c2d12 0%, #b45309 100%)'
  if (name.includes('rau') || name.includes('salad') || name.includes('nấm')) return 'linear-gradient(135deg, #14532d 0%, #15803d 100%)'
  if (name.includes('cơm') || name.includes('rice')) return 'linear-gradient(135deg, #713f12 0%, #a16207 100%)'
  return 'linear-gradient(135deg, #9a3412 0%, #ea580c 100%)'
}

const thumbnails = computed(() => {
  if (!props.item) return []
  const name = props.item.name.toLowerCase()
  const mainEmoji = getEmojiByName(props.item.name)
  const mainGradient = getGradientByName(props.item.name)
  
  return [
    { emoji: mainEmoji, gradient: mainGradient, label: t('customer.itemDetail.overview') },
    { emoji: getDetailEmoji(name), gradient: getDetailGradient(name), label: t('customer.itemDetail.preparation') },
    { emoji: '🌾', gradient: 'linear-gradient(135deg, #451a03 0%, #78350f 100%)', label: t('customer.itemDetail.ingredients') },
    { emoji: '👨‍🍳', gradient: 'linear-gradient(135deg, #18181b 0%, #27272a 100%)', label: t('customer.itemDetail.plating') }
  ]
})

const currentEmoji = computed(() => {
  if (thumbnails.value.length === 0) return '🍲'
  return thumbnails.value[selectedThumb.value]?.emoji || '🍲'
})

const currentGradient = computed(() => {
  if (thumbnails.value.length === 0) return 'linear-gradient(135deg, #1e1b4b 0%, #3730a3 100%)'
  return thumbnails.value[selectedThumb.value]?.gradient || 'linear-gradient(135deg, #1e1b4b 0%, #3730a3 100%)'
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

const handleBack = () => {
  emit('close')
}

const handleGoToCart = () => {
  emit('go-to-cart')
}

const handleSelectThumb = (index: number) => {
  selectedThumb.value = index
}

const increaseQty = () => {
  if (quantity.value < 10) quantity.value++
}

const decreaseQty = () => {
  if (quantity.value > 1) quantity.value--
}

const handleAddToCart = () => {
  if (!props.item) return
  emit('add', props.item, quantity.value, chefNote.value)
}

const resetState = () => {
  chefNote.value = ''
  quantity.value = 1
  selectedThumb.value = 0
}

watch(() => props.isOpen, (newVal) => {
  if (newVal) {
    resetState()
  }
})
</script>

<style scoped>
.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.85);
  backdrop-filter: blur(12px);
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.modal-container {
  background: #18181b;
  width: 100%;
  height: 100%;
  max-width: 960px;
  max-height: 640px;
  border-radius: 24px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.7);
}

.modal-header {
  height: 64px;
  flex-shrink: 0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 24px;
  background: #141417;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.btn-back, .btn-cart {
  position: relative;
  z-index: 10;
  pointer-events: auto;
  padding: 8px 18px;
  border: none;
  border-radius: 14px;
  font-weight: 800;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  font-size: 13px;
}

.btn-back {
  background: #27272a;
  color: #f4f4f5;
  width: 40px;
  height: 40px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
}

.btn-back:hover {
  background: #3f3f46;
  color: white;
}

.btn-back:active {
  transform: scale(0.95);
}

.btn-cart {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  color: #000000;
  box-shadow: 0 4px 14px rgba(245, 158, 11, 0.3);
}

.btn-cart:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 18px rgba(245, 158, 11, 0.4);
}

.btn-cart:active {
  transform: scale(0.95);
}

.modal-body {
  flex: 1;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  padding: 24px;
  overflow-y: auto;
  min-height: 0;
}

.gallery-column {
  display: flex;
  flex-direction: column;
  gap: 14px;
  min-height: 0;
}

.main-image {
  flex: 1;
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.5);
  min-height: 200px;
}

.main-emoji {
  font-size: 100px;
  filter: drop-shadow(0 10px 20px rgba(0, 0, 0, 0.5));
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
  font-size: 11px;
  font-weight: 700;
  backdrop-filter: blur(8px);
}

.thumbnails-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
  flex-shrink: 0;
}

.thumbnail {
  aspect-ratio: 1;
  border-radius: 14px;
  border: 2px solid transparent;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  transition: all 0.2s ease;
  position: relative;
  overflow: hidden;
  padding: 6px;
  background: #27272a;
}

.thumbnail:hover {
  border-color: rgba(245, 158, 11, 0.5);
}

.thumbnail.active {
  border-color: #f59e0b;
  box-shadow: 0 0 0 2px rgba(245, 158, 11, 0.3);
  transform: translateY(-2px);
}

.thumb-emoji {
  font-size: 28px;
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.4));
}

.thumb-label {
  font-size: 10px;
  font-weight: 700;
  color: white;
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.9);
}

.info-column {
  display: flex;
  flex-direction: column;
  gap: 16px;
  overflow: hidden;
}

.item-name {
  font-size: 24px;
  font-weight: 800;
  color: #ffffff;
  margin: 0;
  line-height: 1.25;
  flex-shrink: 0;
}

.item-price {
  font-size: 22px;
  font-weight: 900;
  color: #f59e0b;
  flex-shrink: 0;
}

.item-price.free {
  color: #10b981;
}

.description-box {
  background: #27272a;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 16px;
  padding: 16px;
  flex-shrink: 0;
}

.section-label {
  font-size: 11px;
  font-weight: 800;
  color: #a1a1aa;
  text-transform: uppercase;
  letter-spacing: 1px;
  margin: 0 0 8px 0;
}

.description-text {
  font-size: 13px;
  color: #e4e4e7;
  line-height: 1.5;
  margin: 0;
}

.attributes-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
  flex-shrink: 0;
}

.attr-card {
  background: #27272a;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 14px;
  padding: 12px 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  text-align: center;
}

.attr-icon {
  font-size: 20px;
}

.attr-label {
  font-size: 10px;
  color: #a1a1aa;
  font-weight: 600;
}

.attr-value {
  font-size: 12px;
  font-weight: 700;
  color: #f4f4f5;
}

.attr-value.highlight {
  color: #f59e0b;
}

.modal-footer {
  padding: 16px 24px 20px;
  background: #141417;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  gap: 14px;
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
  gap: 8px;
  background: #27272a;
  border-radius: 14px;
  padding: 4px;
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.qty-btn {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  background: #3f3f46;
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: #ffffff;
  font-size: 18px;
  font-weight: 800;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
}

.qty-btn:hover {
  background: #f59e0b;
  color: #000000;
}

.qty-btn:active {
  transform: scale(0.95);
}

.qty-value {
  font-size: 16px;
  font-weight: 800;
  color: #ffffff;
  min-width: 28px;
  text-align: center;
}

.note-input {
  width: 100%;
  background: #27272a;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 14px;
  padding: 10px 14px;
  color: #ffffff;
  font-size: 13px;
  font-family: inherit;
  transition: border-color 0.2s;
}

.note-input:focus {
  outline: none;
  border-color: #f59e0b;
  box-shadow: 0 0 0 2px rgba(245, 158, 11, 0.2);
}

.note-input::placeholder {
  color: #71717a;
}

.btn-add-cart {
  width: 100%;
  padding: 14px;
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  border: none;
  border-radius: 14px;
  color: #000000;
  font-size: 14px;
  font-weight: 900;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  box-shadow: 0 4px 16px rgba(245, 158, 11, 0.3);
}

.btn-add-cart:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(245, 158, 11, 0.45);
}

.btn-add-cart:active {
  transform: scale(0.98);
}

@media (max-width: 768px) {
  .modal-overlay {
    padding: 0;
  }

  .modal-container {
    height: 100%;
    max-height: 100%;
    border-radius: 0;
  }
  
  .modal-body {
    grid-template-columns: 1fr;
    gap: 16px;
  }
  
  .main-image {
    min-height: 160px;
  }
  
  .main-emoji {
    font-size: 70px;
  }
  
  .footer-row {
    grid-template-columns: 1fr;
  }
}
</style>

