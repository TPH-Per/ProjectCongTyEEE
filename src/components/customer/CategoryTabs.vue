<!-- File: src/components/customer/CategoryTabs.vue -->
<template>
  <div class="category-tabs-container scrollbar-hide">
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
  emit('update:selected-tab', tabId)
}
</script>

<style scoped>
.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.category-tabs-container {
  position: relative;
  background: #141417;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  padding: 10px 20px;
  overflow-x: auto;
  overflow-y: hidden;
  width: 100%;
  box-sizing: border-box;
  pointer-events: auto;
  z-index: 10;
}

.category-tabs-wrapper {
  display: flex;
  flex-wrap: nowrap;
  gap: 8px;
  align-items: center;
  width: max-content;
}

.tab-button {
  padding: 8px 16px;
  background: #1e1e24;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 12px;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  flex-shrink: 0;
  min-height: 36px;
  color: #a1a1aa;
}

.tab-button:hover {
  background: #27272a;
  color: #f4f4f5;
  border-color: rgba(255, 255, 255, 0.15);
  transform: translateY(-1px);
}

.tab-button.active {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  border-color: #f59e0b;
  box-shadow: 0 4px 14px rgba(245, 158, 11, 0.35);
  color: #000000;
}

.tab-name {
  font-size: 12px;
  font-weight: 700;
  white-space: nowrap;
}

.tab-button.active .tab-name {
  color: #000000;
}

.tab-count {
  background: rgba(255, 255, 255, 0.1);
  padding: 2px 7px;
  border-radius: 8px;
  font-size: 10px;
  font-weight: 800;
  color: #a1a1aa;
  min-width: 20px;
  text-align: center;
}

.tab-button.active .tab-count {
  background: rgba(0, 0, 0, 0.25);
  color: #000000;
}

/* Responsive */
@media (max-width: 768px) {
  .category-tabs-container {
    padding: 8px 14px;
  }
  
  .tab-button {
    padding: 6px 12px;
    min-height: 32px;
  }
  
  .tab-name {
    font-size: 11px;
  }
}
</style>


