<!--
  ToggleSwitch.vue
  ----------------
  Tiny iOS-style toggle used across the back-office. v-model:modelValue
  with a Boolean. `size="sm"` is the compact variant for table rows.
-->
<script setup lang="ts">
withDefaults(
  defineProps<{
    modelValue: boolean
    size?: 'sm' | 'md'
    ariaLabel?: string
  }>(),
  { size: 'md', ariaLabel: 'Toggle' },
)

defineEmits<{
  (e: 'update:modelValue', value: boolean): void
}>()
</script>

<template>
  <label class="relative inline-flex items-center cursor-pointer select-none" :aria-label="ariaLabel">
    <input
      type="checkbox"
      class="sr-only"
      :checked="modelValue"
      @change="$emit('update:modelValue', ($event.target as HTMLInputElement).checked)"
    />
    <span
      :class="[
        'block rounded-full transition-colors',
        size === 'sm' ? 'w-8 h-5' : 'w-10 h-6',
        modelValue ? 'bg-emerald-500' : 'bg-gray-300',
      ]"
    />
    <span
      :class="[
        'absolute left-1 top-1 bg-white rounded-full transition-transform shadow-sm',
        size === 'sm' ? 'w-3 h-3' : 'w-4 h-4',
        modelValue ? (size === 'sm' ? 'translate-x-3' : 'translate-x-4') : '',
      ]"
    />
  </label>
</template>