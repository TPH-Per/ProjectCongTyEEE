<script setup lang="ts">
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { Star, Tag } from 'lucide-vue-next';
import { useMembership } from '@/composables/useMembership';

const props = defineProps<{
  orderTotal: number;
  customer?: any;
  pointsToRedeem?: number;
}>();

const { t, locale } = useI18n();
const { previewEarnPoints, previewRedeemValue, rules } = useMembership();

const formatCurrency = (val: number) => {
  return new Intl.NumberFormat(locale.value === 'en' ? 'en-US' : 'vi-VN', {
    style: 'currency',
    currency: 'VND'
  }).format(val);
};

const earnedPoints = computed(() => {
  const multiplier = props.customer?.tier?.points_multiplier || 1.0;
  return previewEarnPoints(props.orderTotal, multiplier);
});

const discountValue = computed(() => {
  return previewRedeemValue(props.pointsToRedeem || 0);
});
</script>

<template>
  <div class="space-y-2">
    <!-- Earn Preview -->
    <div v-if="orderTotal > 0" class="flex items-center gap-2 p-3 bg-neutral-900/50 border border-neutral-800 rounded-lg">
      <div class="w-8 h-8 rounded-full bg-amber-500/20 flex items-center justify-center text-amber-500 shrink-0">
        <Star class="w-4 h-4 fill-amber-500" />
      </div>
      <div>
        <p class="text-sm font-medium text-amber-500">
          {{ t('membership.earn_preview', { points: earnedPoints }) }}
        </p>
        <p v-if="customer?.tier" class="text-xs text-neutral-500">
          {{ customer.tier.name_vi }} ({{ customer.tier.points_multiplier }}x multiplier)
        </p>
      </div>
    </div>

    <!-- Redeem Preview -->
    <div v-if="pointsToRedeem && pointsToRedeem > 0" class="flex items-center gap-2 p-3 bg-neutral-900/50 border border-neutral-800 rounded-lg">
      <div class="w-8 h-8 rounded-full bg-green-500/20 flex items-center justify-center text-green-500 shrink-0">
        <Tag class="w-4 h-4" />
      </div>
      <div>
        <p class="text-sm font-medium text-green-400">
          {{ t('membership.redeem_preview', { points: pointsToRedeem, amount: formatCurrency(discountValue) }) }}
        </p>
        <p v-if="rules?.min_redeem_points && pointsToRedeem < rules.min_redeem_points" class="text-xs text-red-400 mt-0.5">
          {{ t('membership.error.below_min', { min: rules.min_redeem_points }) }}
        </p>
      </div>
    </div>
  </div>
</template>
