<!-- IngredientSelector.vue -->
<template>
  <div class="ingredient-selector">
    <div class="search-box">
      <span class="search-icon">🔍</span>
      <input 
        v-model="searchQuery"
        type="text"
        placeholder="Tìm kiếm nguyên liệu cần xuất..."
        class="search-input"
        aria-label="Tìm kiếm nguyên liệu"
      />
    </div>

    <!-- Search Results / Inventory items -->
    <div class="ingredient-list max-h-[350px] overflow-y-auto pr-1">
      <div v-if="filteredItems.length === 0" class="text-center py-8 text-muted-foreground">
        Không tìm thấy nguyên liệu nào khớp.
      </div>
      <div 
        v-else
        v-for="item in filteredItems" 
        :key="item.ingredient_id"
        class="ingredient-item"
        :class="{ selected: isSelected(item.ingredient_id) }"
        @click="toggleSelect(item)"
      >
        <div class="ingredient-header">
          <input 
            type="checkbox" 
            :checked="isSelected(item.ingredient_id)"
            class="ingredient-checkbox"
            @click.stop="toggleSelect(item)"
            aria-label="Chọn nguyên liệu"
          />
          <span class="ingredient-name">{{ item.name_vi }}</span>
          
          <div v-if="isSelected(item.ingredient_id)" class="quantity-control flex items-center gap-2" @click.stop>
            <label :for="`qty-${item.ingredient_id}`" class="sr-only">Số lượng</label>
            <input 
              :id="`qty-${item.ingredient_id}`"
              v-model.number="selectedQuantities[item.ingredient_id]"
              type="number"
              min="1"
              class="quantity-input"
              @change="updateQty(item.ingredient_id, selectedQuantities[item.ingredient_id])"
            />
            <span class="text-xs text-muted-foreground font-bold uppercase">{{ item.unit }}</span>
          </div>
        </div>

        <div class="ingredient-stocks">
          <div class="stock-info">
            <span class="stock-label">Tồn kho bếp:</span>
            <span class="stock-value font-mono" :class="getStockLevelClass(item.quantity, item.low_stock_threshold)">
              {{ item.quantity }} {{ item.unit }} (Tối thiểu: {{ item.low_stock_threshold }}{{ item.unit }})
            </span>
          </div>
          <div class="stock-info">
            <span class="stock-label">Phân loại:</span>
            <span class="stock-value font-mono good">
              {{ item.category_name_vi }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import type { InventoryItemWithAlerts } from '@/composables/useInventory';

const props = defineProps<{
  inventory: InventoryItemWithAlerts[];
  modelValue: Array<{ ingredient_id: string; requested_quantity: number }>;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: Array<{ ingredient_id: string; requested_quantity: number }>): void;
}>();

const searchQuery = ref('');
const selectedQuantities = ref<Record<string, number>>({});

// Keep track of selections
const selectedItemIds = computed(() => props.modelValue.map(i => i.ingredient_id));

// Watch modelValue to sync internal state
watch(() => props.modelValue, (newVal) => {
  newVal.forEach(item => {
    if (selectedQuantities.value[item.ingredient_id] !== item.requested_quantity) {
      selectedQuantities.value[item.ingredient_id] = item.requested_quantity;
    }
  });
}, { immediate: true, deep: true });

const filteredItems = computed(() => {
  if (!searchQuery.value.trim()) return props.inventory;
  const q = searchQuery.value.toLowerCase();
  return props.inventory.filter(i => i.name_vi.toLowerCase().includes(q));
});

const isSelected = (id: string) => {
  return selectedItemIds.value.includes(id);
};

const toggleSelect = (item: InventoryItemWithAlerts) => {
  const current = [...props.modelValue];
  const idx = current.findIndex(i => i.ingredient_id === item.ingredient_id);
  
  if (idx > -1) {
    // Unselect
    current.splice(idx, 1);
    delete selectedQuantities.value[item.ingredient_id];
  } else {
    // Select with a default quantity
    const defaultQty = Math.max(1, item.low_stock_threshold - item.quantity);
    current.push({ ingredient_id: item.ingredient_id, requested_quantity: defaultQty });
    selectedQuantities.value[item.ingredient_id] = defaultQty;
  }
  
  emit('update:modelValue', current);
};

const updateQty = (id: string, qty: number) => {
  const current = [...props.modelValue];
  const item = current.find(i => i.ingredient_id === id);
  if (item) {
    item.requested_quantity = Math.max(1, qty);
    emit('update:modelValue', current);
  }
};

const getStockLevelClass = (stock: number, min: number) => {
  if (stock === 0) return 'low';
  if (stock < min) return 'warning';
  return 'good';
};
</script>

<style scoped>
.search-box {
  position: relative;
  margin-bottom: 16px;
}

.search-icon {
  position: absolute;
  left: 14px;
  top: 50%;
  transform: translateY(-50%);
  color: #B0B0B0;
  font-size: 16px;
}

.search-input {
  width: 100%;
  padding: 12px 14px 12px 44px;
  background: #1A1A1A;
  border: 1px solid #404040;
  border-radius: 8px;
  color: #FFFFFF;
  font-size: 14px;
  outline: none;
  transition: all 0.2s ease;
}

.search-input:focus {
  border-color: #FF9800;
  box-shadow: 0 0 0 3px rgba(255, 152, 0, 0.2);
}

.ingredient-item {
  background: #1A1A1A;
  border: 2px solid #404040;
  border-radius: 10px;
  padding: 16px;
  margin-bottom: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
  user-select: none;
}

.ingredient-item:hover {
  border-color: #616161;
}

.ingredient-item.selected {
  border-color: #FF9800;
  background: linear-gradient(135deg, #1A1A1A 0%, #2D2517 100%);
}

.ingredient-header {
  display: flex;
  align-items: center;
  gap: 12px;
}

.ingredient-checkbox {
  width: 20px;
  height: 20px;
  cursor: pointer;
}

.ingredient-icon {
  font-size: 24px;
}

.ingredient-name {
  flex: 1;
  font-size: 16px;
  font-weight: 600;
  color: #FFFFFF;
}

.quantity-control {
  margin-left: auto;
}

.quantity-input {
  width: 80px;
  padding: 6px 10px;
  background: #2D2D2D;
  border: 1px solid #404040;
  border-radius: 6px;
  color: #FFFFFF;
  font-size: 14px;
  font-weight: 600;
  text-align: center;
}

.ingredient-stocks {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #404040;
}

.stock-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stock-label {
  font-size: 11px;
  color: #B0B0B0;
  text-transform: uppercase;
}

.stock-value {
  font-size: 13px;
  font-weight: 600;
}

.stock-value.low {
  color: #F44336;
}

.stock-value.warning {
  color: #FF9800;
}

.stock-value.good {
  color: #4CAF50;
}
</style>
