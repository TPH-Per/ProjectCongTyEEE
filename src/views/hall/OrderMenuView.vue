<template>
  <div class="order-menu-container">
    <div class="menu-header">
      <h2>Chọn món - Bàn {{ tableCode || 'Chưa chọn' }}</h2>
      <div class="categories">
        <button 
          v-for="cat in categories"
          :key="cat.id"
          :class="['category-btn', { active: activeCategory === cat.id }]"
          @click="activeCategory = cat.id"
        >
          {{ cat.name }}
        </button>
      </div>
    </div>

    <div v-if="filteredMenuItems.length === 0" class="no-items">
      Không tìm thấy món ăn nào thuộc nhóm này.
    </div>

    <div v-else class="menu-grid">
      <div 
        v-for="item in filteredMenuItems" 
        :key="item.id"
        class="menu-item-card"
        @click="addToOrder(item)"
      >
        <div class="item-image">{{ item.image || '🍽️' }}</div>
        <div class="item-info">
          <h3 class="item-name">{{ item.name }}</h3>
          <p class="item-price">{{ formatVND(item.price) }}</p>
        </div>
        <button class="add-btn">+</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import Swal from 'sweetalert2'

const props = defineProps<{
  menuItems: any[]
  tableCode: string | null
}>()

const activeCategory = ref('all')

const categories = [
  { id: 'all', name: 'Tất cả' },
  { id: 'buffet', name: 'Buffet' },
  { id: 'set-lunch', name: 'Set Lunch' },
  { id: 'food', name: 'Thức ăn' },
  { id: 'drink', name: 'Đồ uống' }
]

const filteredMenuItems = computed(() => {
  if (activeCategory.value === 'all') return props.menuItems
  return props.menuItems.filter(item => item.category === activeCategory.value)
})

function formatVND(amount: number): string {
  return amount.toLocaleString('vi-VN') + 'đ'
}

function addToOrder(item: any) {
  Swal.fire({
    title: 'Thành công',
    text: `Đã thêm món ${item.name} cho bàn ${props.tableCode || 'mới'}`,
    icon: 'success',
    toast: true,
    position: 'top-end',
    showConfirmButton: false,
    timer: 1200
  })
}
</script>

<style scoped>
.order-menu-container {
  padding: 20px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
}

.menu-header {
  border-bottom: 1px solid #e5e7eb;
  padding-bottom: 16px;
  margin-bottom: 20px;
}

.menu-header h2 {
  font-size: 18px;
  font-weight: 800;
  color: #111827;
  margin: 0 0 16px 0;
}

.categories {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.category-btn {
  padding: 8px 16px;
  border-radius: 20px;
  border: 1px solid #d1d5db;
  background: white;
  font-size: 13px;
  font-weight: 700;
  color: #4b5563;
  cursor: pointer;
  transition: all 0.2s;
}

.category-btn:hover {
  border-color: #f97316;
  color: #f97316;
}

.category-btn.active {
  background: #f97316;
  color: white;
  border-color: #f97316;
}

.no-items {
  text-align: center;
  padding: 40px;
  color: #6b7280;
  font-weight: 600;
}

.menu-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 16px;
  margin-top: 20px;
}

.menu-item-card {
  background: #f9fafb;
  border-radius: 12px;
  padding: 16px;
  cursor: pointer;
  transition: all 0.2s;
  border: 2px solid transparent;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  height: 180px;
}

.menu-item-card:hover {
  border-color: #f97316;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.05);
}

.item-image {
  font-size: 40px;
  text-align: center;
  margin-bottom: 8px;
}

.item-info {
  flex-grow: 1;
}

.item-name {
  font-size: 14px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 6px 0;
  line-height: 1.3;
}

.item-price {
  font-size: 15px;
  font-weight: 800;
  color: #f97316;
  margin: 0;
}

.add-btn {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: #f97316;
  color: white;
  border: none;
  font-size: 18px;
  font-weight: bold;
  cursor: pointer;
  align-self: flex-end;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s;
}

.add-btn:hover {
  background: #ea580c;
}
</style>
