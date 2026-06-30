<script setup lang="ts">
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { Award, Shield, Star, Gem, Circle } from 'lucide-vue-next';

const props = withDefaults(defineProps<{
  tier?: {
    name_vi?: string;
    name_en?: string;
    name_ja?: string;
    color?: string;
    icon_name?: string;
    discount_percent?: number;
  };
  size?: 'sm' | 'md' | 'lg';
}>(), {
  size: 'md'
});

const { locale } = useI18n();

const tierName = computed(() => {
  if (!props.tier) return '';
  switch(locale.value) {
    case 'en': return props.tier.name_en || props.tier.name_vi;
    case 'ja': return props.tier.name_ja || props.tier.name_vi;
    default: return props.tier.name_vi;
  }
});

const shortName = computed(() => {
  if (!tierName.value) return '';
  const parts = tierName.value.trim().split(/\s+/);
  if (parts.length > 1) {
    return parts.map(p => p.charAt(0)).join('').toUpperCase().substring(0, 2);
  }
  return tierName.value.substring(0, 2).toUpperCase();
});

const iconMap: Record<string, any> = {
  award: Award,
  shield: Shield,
  star: Star,
  gem: Gem
};

const iconComponent = computed(() => {
  return iconMap[props.tier?.icon_name || ''] || Circle;
});

const colorStyle = computed(() => {
  if (!props.tier?.color) return {};
  const hex = props.tier.color.replace('#', '');
  let r = 0, g = 0, b = 0;
  if (hex.length === 6) {
    r = parseInt(hex.substring(0, 2), 16);
    g = parseInt(hex.substring(2, 4), 16);
    b = parseInt(hex.substring(4, 6), 16);
  }
  return {
    backgroundColor: `rgba(${r}, ${g}, ${b}, 0.15)`,
    color: props.tier.color,
    borderColor: props.tier.color
  };
});
</script>

<template>
  <div v-if="tier" :class="[
    'inline-flex items-center justify-center font-medium border rounded-full whitespace-nowrap',
    size === 'sm' ? 'px-2 py-0.5 text-xs gap-1' : '',
    size === 'md' ? 'px-2.5 py-1 text-sm gap-1.5' : '',
    size === 'lg' ? 'px-3 py-1.5 text-base gap-2' : ''
  ]" :style="colorStyle">
    <component :is="iconComponent" :size="size === 'sm' ? 12 : size === 'md' ? 14 : 18" />
    <span v-if="size === 'sm'">{{ shortName }}</span>
    <span v-else>{{ tierName }}</span>
    <span v-if="size === 'lg' && tier.discount_percent && tier.discount_percent > 0" class="ml-1 opacity-80 text-sm">
      · -{{ tier.discount_percent }}%
    </span>
  </div>
</template>
