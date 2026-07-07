<!-- File: src/components/reception/HamburgerMenu.vue -->
<template>
  <button 
    class="hamburger-btn"
    @click="$emit('toggle')"
    :class="{ active: isActive }"
  >
    <span class="hamburger-line"></span>
    <span class="hamburger-line"></span>
    <span class="hamburger-line"></span>
  </button>
</template>

<script setup lang="ts">
defineProps<{
  isActive?: boolean
}>()

defineEmits<{
  'toggle': []
}>()
</script>

<style scoped>
.hamburger-btn {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  background: #E8772E;
  border: none;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  transition: all 0.3s;
  padding: 8px;
  box-shadow: 0 2px 6px rgba(232, 119, 46, 0.3);
}

.hamburger-btn:hover {
  background: #d4631b;
}

.hamburger-btn.active {
  background: #E8772E;
}

.hamburger-line {
  width: 100%;
  height: 2px;
  background: white;
  border-radius: 2px;
  transition: all 0.3s;
}

.hamburger-btn.active .hamburger-line:nth-child(1) {
  transform: translateY(6px) rotate(45deg);
}

.hamburger-btn.active .hamburger-line:nth-child(2) {
  opacity: 0;
}

.hamburger-btn.active .hamburger-line:nth-child(3) {
  transform: translateY(-6px) rotate(-45deg);
}
</style>
