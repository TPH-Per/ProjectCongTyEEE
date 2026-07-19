<template>
  <!-- Overlay: opacity-only transition (no transform shift = no jerk) -->
  <Transition name="menu-overlay">
    <div
      v-if="isOpen"
      class="fixed inset-0 z-[9998] bg-black/30 backdrop-blur-xs"
      @click="emit('close')"
    ></div>
  </Transition>

  <!-- Popup: smooth scale+fade, no overshoot bounce -->
  <Transition name="menu-popup">
    <div
      v-if="isOpen"
      class="fixed z-[9999] w-80 bg-white rounded-2xl shadow-2xl overflow-hidden border border-gray-200"
      :style="menuStyle"
      @click.stop
    >
      <!-- Header -->
      <div
        class="bg-gradient-to-r from-blue-600 to-indigo-600 px-5 py-4"
      >
        <div class="flex items-center gap-3">
          <div
            class="w-10 h-10 bg-white/20 rounded-lg flex items-center justify-center backdrop-blur-sm"
          >
            <span class="text-xl">📋</span>
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-sm font-bold text-white truncate">
              Bàn {{ table?.code }}
            </div>
            <div class="text-xs text-blue-100 truncate">
              {{ table?.customerName || "Khách vãng lai" }}
            </div>
          </div>
          <button
            @click="emit('close')"
            class="w-8 h-8 rounded-lg bg-white/20 hover:bg-white/30 flex items-center justify-center transition-colors shrink-0"
            type="button"
          >
            <span class="text-white text-sm">✕</span>
          </button>
        </div>
      </div>

      <!-- Menu Items -->
      <div class="p-3 space-y-1.5">
        <button
          v-for="action in actions"
          :key="action.id"
          @click="emit('action', action.id)"
          class="w-full group flex items-center gap-3 p-2.5 rounded-xl transition-all duration-200 hover:shadow-md hover:-translate-y-0.5"
          :class="
            action.isPrimary
              ? 'bg-gradient-to-r from-green-50 to-emerald-50 border-2 border-green-500 hover:border-green-600'
              : 'border-2 border-transparent hover:bg-gray-50'
          "
          type="button"
        >
          <div
            class="w-11 h-11 rounded-xl flex items-center justify-center text-xl shadow-sm group-hover:scale-110 transition-transform shrink-0"
            :class="action.colorClass"
          >
            {{ action.icon }}
          </div>
          <div class="flex-1 text-left min-w-0">
            <div
              class="font-bold text-gray-800 text-sm"
              :class="
                action.isPrimary
                  ? 'text-green-800 font-extrabold text-base'
                  : 'group-hover:text-gray-900'
              "
            >
              {{ action.label }}
            </div>
            <div
              class="text-xs text-gray-500 truncate"
              :class="action.isPrimary ? 'text-green-700 font-medium' : ''"
            >
              {{ action.description }}
              <span v-if="action.id === 'select_items'">{{ table?.code }}</span>
            </div>
          </div>
          <span
            class="text-gray-300 group-hover:text-gray-400 group-hover:translate-x-1 transition-all shrink-0"
            :class="action.isPrimary ? 'text-green-600' : ''"
            >➡️</span
          >
        </button>
      </div>

      <!-- Footer -->
      <div class="px-3 py-2.5 bg-gray-50 border-t border-gray-100 flex justify-end">
        <button
          @click="emit('close')"
          class="px-4 py-2 bg-gray-200 hover:bg-gray-300 text-gray-700 font-bold text-sm rounded-lg transition-colors active:scale-95"
          type="button"
        >
          Hủy
        </button>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { computed } from "vue";

const props = defineProps<{
  isOpen: boolean;
  table: any;
  actions: any[];
  position: { x: number; y: number };
}>();

const emit = defineEmits<{
  close: [];
  action: [actionId: string];
}>();

// Auto-position: flip up if near bottom edge, clamp to viewport
const menuStyle = computed(() => {
  const x = props.position.x;
  const y = props.position.y;

  const menuWidth = 320; // w-80
  const menuHeight = 420; // approx: header + 6 items + footer

  const viewportWidth = window.innerWidth;
  const viewportHeight = window.innerHeight;

  const adjustedX =
    x + menuWidth > viewportWidth
      ? viewportWidth - menuWidth - 10
      : Math.max(10, x);

  const spaceBelow = viewportHeight - y;
  const shouldFlipUp = spaceBelow < menuHeight;

  const adjustedY = shouldFlipUp
    ? Math.max(10, y - menuHeight - 10)
    : y;

  return {
    left: `${adjustedX}px`,
    top: `${adjustedY}px`,
    transformOrigin: shouldFlipUp ? "bottom left" : "top left",
  };
});
</script>

<style scoped>
/* Overlay: opacity-only — no transform shift (fixes jerk) */
.menu-overlay-enter-active,
.menu-overlay-leave-active {
  transition: opacity 0.15s ease;
}
.menu-overlay-enter-from,
.menu-overlay-leave-to {
  opacity: 0;
}

/* Popup: smooth scale+fade, ease-out, no overshoot */
.menu-popup-enter-active {
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}
.menu-popup-leave-active {
  transition: all 0.15s ease-in;
}
.menu-popup-enter-from,
.menu-popup-leave-to {
  opacity: 0;
  transform: scale(0.92);
}

/* Prevent layout shift / flicker */
.menu-popup-enter-active,
.menu-popup-leave-active {
  will-change: transform, opacity;
  backface-visibility: hidden;
}
</style>
