<!-- File: src/components/customer/CategoryTabs.vue -->
<template>
  <div class="category-tabs-container">
    <div class="category-tabs-wrapper">
      <!-- Tab "Tất cả" -->
      <button
        class="tab-button"
        :class="{ active: selectedTab === 'all' }"
        @click="selectTab('all')"
        type="button"
      >
        <span class="tab-name">{{ $t('customer.categoryTabs.all') }}</span>
        <span class="tab-count">{{ totalItems }}</span>
      </button>

      <!-- Các tabs subcategories -->
      <button
        v-for="sub in subcategories"
        :key="sub.id"
        class="tab-button"
        :class="{ active: selectedTab === sub.id }"
        @click="selectTab(sub.id)"
        type="button"
      >
        <span class="tab-name">{{ sub.name }}</span>
        <span class="tab-count">{{ sub.items.length }}</span>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { SubCategory } from '@/data/menuData'

defineProps<{
  subcategories: SubCategory[]
  selectedTab: string
  totalItems: number
}>()

const emit = defineEmits<{
  (e: 'update:selected-tab', value: string): void
}>()

const selectTab = (tabId: string) => {
  console.log('Select subcategory tab clicked:', tabId)
  emit('update:selected-tab', tabId)
}
</script>

<style scoped>
.category-tabs-container {
  position: relative;
  background: #1a1a1a;
  padding: 16px 24px 20px;
  max-height: 200px;
  overflow-y: auto;
  width: 100%;
  box-sizing: border-box;
  pointer-events: auto; /* Enable click/touch events inside fixed-bottom-container */
}

.category-tabs-wrapper {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  justify-content: flex-start;
}

.tab-button {
  padding: 10px 18px;
  background: #2d2d2d;
  border: 2px solid transparent;
  border-radius: 12px;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s;
  flex-shrink: 0;
  min-height: 44px;
  color: white;
}

.tab-button:hover {
  background: #3d3d3d;
  transform: translateY(-2px);
}

.tab-button.active {
  background: linear-gradient(135deg, #ff9800 0%, #ffb74d 100%);
  border-color: #ff9800;
  box-shadow: 0 4px 12px rgba(255, 152, 0, 0.4);
}

.tab-name {
  font-size: 13px;
  font-weight: 600;
  color: #e0e0e0;
  white-space: nowrap;
}

.tab-button.active .tab-name {
  color: #1a1a1a;
}

.tab-count {
  background: rgba(255, 255, 255, 0.15);
  padding: 2px 8px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: 700;
  color: #b0b0b0;
  min-width: 24px;
  text-align: center;
}

.tab-button.active .tab-count {
  background: rgba(0, 0, 0, 0.2);
  color: #1a1a1a;
}

/* Tablet */
@media (max-width: 1200px) {
  .category-tabs-container {
    padding: 16px 20px 20px;
  }
  
  .tab-button {
    padding: 8px 14px;
    min-height: 40px;
  }
  
  .tab-name {
    font-size: 12px;
  }
  
  .tab-count {
    font-size: 10px;
    padding: 2px 6px;
  }
}

/* Mobile */
@media (max-width: 768px) {
  .category-tabs-container {
    padding: 12px 16px 16px;
    background: #1a1a1a;
  }
  
  .category-tabs-wrapper {
    gap: 8px;
  }
  
  .tab-button {
    padding: 8px 12px;
    min-height: 38px;
    border-radius: 10px;
  }
  
  .tab-name {
    font-size: 11px;
  }
  
  .tab-count {
    font-size: 10px;
    min-width: 20px;
    padding: 2px 5px;
  }
}
</style>
