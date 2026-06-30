<script setup lang="ts">
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { X, Plus, ArrowUp, ArrowDown, Pencil, Star } from 'lucide-vue-next';
import TierBadge from './TierBadge.vue';
import { useMembership } from '@/composables/useMembership';
import { useCustomer } from '@/composables/useCustomer';

const props = defineProps<{
  modelValue: boolean;
  customerId: string | null;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void;
}>();

const { t, locale } = useI18n();
const { adjustPoints } = useMembership();
const { getCustomerProfile } = useCustomer();

const loading = ref(false);
const profile = ref<any>(null);

const showAdjustModal = ref(false);
const adjustForm = ref({
  type: 'ADJUST_ADD' as 'ADJUST_ADD' | 'ADJUST_SUB',
  points: 0,
  reason: ''
});
const adjustLoading = ref(false);

watch(() => props.modelValue, async (newVal) => {
  if (newVal && props.customerId) {
    await loadProfile();
  } else {
    profile.value = null;
  }
});

async function loadProfile() {
  loading.value = true;
  try {
    profile.value = await getCustomerProfile(props.customerId!);
  } catch (err) {
    console.error('Failed to load profile:', err);
  } finally {
    loading.value = false;
  }
}

function closeDrawer() {
  emit('update:modelValue', false);
}

const avatarColor = computed(() => {
  return profile.value?.tier?.color || '#9ca3af';
});

const avatarInitials = computed(() => {
  const name = profile.value?.customer?.name;
  if (!name) return '?';
  return name.charAt(0).toUpperCase();
});

const progressPercent = computed(() => {
  if (!profile.value?.next_tier) return 100;
  const spent = profile.value.customer.total_spent || 0;
  const minSpent = profile.value.next_tier.min_spent || 1;
  const progress = (spent / minSpent) * 100;
  return Math.min(progress, 100);
});

function formatCurrency(val: number) {
  if (val == null) return '';
  return new Intl.NumberFormat(locale.value === 'en' ? 'en-US' : 'vi-VN', {
    style: 'currency',
    currency: 'VND'
  }).format(val);
}

function formatDate(val: string) {
  if (!val) return '';
  return new Date(val).toLocaleDateString(locale.value);
}

function formatPoints(val: number) {
  if (val == null) return '0';
  return new Intl.NumberFormat(locale.value).format(val);
}

async function handleAdjustSubmit() {
  if (adjustForm.value.points <= 0) return;
  adjustLoading.value = true;
  try {
    await adjustPoints(
      props.customerId!,
      adjustForm.value.type,
      adjustForm.value.points,
      adjustForm.value.reason
    );
    showAdjustModal.value = false;
    await loadProfile(); // reload
    adjustForm.value = { type: 'ADJUST_ADD', points: 0, reason: '' };
  } catch (err) {
    console.error('Error adjusting points:', err);
    alert('Error adjusting points');
  } finally {
    adjustLoading.value = false;
  }
}
</script>

<template>
  <div>
    <!-- Backdrop -->
    <div 
      v-if="modelValue" 
      class="fixed inset-0 bg-black/60 z-40 transition-opacity"
      @click="closeDrawer"
    ></div>

    <!-- Drawer -->
    <div 
      class="fixed inset-y-0 right-0 z-50 w-full max-w-md bg-neutral-900 border-l border-neutral-800 shadow-2xl transform transition-transform duration-300 flex flex-col"
      :class="modelValue ? 'translate-x-0' : 'translate-x-full'"
    >
      <div class="flex items-center justify-between p-4 border-b border-neutral-800">
        <h2 class="text-lg font-semibold text-neutral-100 font-serif">{{ t('membership.title') }}</h2>
        <button @click="closeDrawer" class="p-2 text-neutral-400 hover:text-white transition-colors rounded-full hover:bg-neutral-800">
          <X class="w-5 h-5" />
        </button>
      </div>

      <div v-if="loading" class="p-8 text-center text-neutral-400">
        <div class="w-8 h-8 border-4 border-amber-500/30 border-t-amber-500 rounded-full animate-spin mx-auto mb-4"></div>
        Loading...
      </div>

      <div v-else-if="profile" class="flex-1 overflow-y-auto p-6 space-y-8">
        
        <!-- Header Section -->
        <div class="flex items-center gap-4">
          <div 
            class="w-16 h-16 rounded-full flex items-center justify-center text-2xl font-bold font-serif shadow-lg"
            :style="{ backgroundColor: `${avatarColor}20`, color: avatarColor, border: `1px solid ${avatarColor}` }"
          >
            {{ avatarInitials }}
          </div>
          <div>
            <h3 class="text-xl font-bold text-white">{{ profile.customer.name }}</h3>
            <p class="text-neutral-400 text-sm mb-2">{{ profile.customer.phone }}</p>
            <div class="flex items-center gap-2">
              <TierBadge v-if="profile.tier" :tier="profile.tier" size="sm" />
              <span class="text-xs text-neutral-500">Joined: {{ formatDate(profile.customer.created_at) }}</span>
            </div>
          </div>
        </div>

        <!-- Points Section -->
        <div class="bg-neutral-800/50 rounded-2xl p-5 border border-neutral-700 relative overflow-hidden">
          <div class="absolute inset-0 bg-gradient-to-br from-amber-500/10 to-transparent pointer-events-none"></div>
          
          <div class="flex justify-between items-start mb-4 relative z-10">
            <div>
              <p class="text-sm text-neutral-400 mb-1">{{ t('membership.points_balance') }}</p>
              <div class="text-3xl font-bold text-amber-400 font-serif flex items-center gap-2">
                <Star class="w-6 h-6 fill-amber-400" />
                {{ formatPoints(profile.customer.current_points) }} 
                <span class="text-lg font-normal text-amber-500/80">{{ t('membership.points').toLowerCase() }}</span>
              </div>
            </div>
            <button 
              @click="showAdjustModal = true"
              class="w-10 h-10 rounded-full bg-neutral-700 hover:bg-neutral-600 flex items-center justify-center text-white transition-colors"
            >
              <Plus class="w-5 h-5" />
            </button>
          </div>

          <div v-if="profile.next_tier" class="space-y-2 relative z-10">
            <div class="flex justify-between text-xs text-neutral-400">
              <span>{{ profile.tier?.name_vi || 'Thành viên' }}</span>
              <span>{{ profile.next_tier.name_vi }}</span>
            </div>
            <div class="h-2 bg-neutral-700 rounded-full overflow-hidden">
              <div class="h-full bg-amber-500 rounded-full" :style="{ width: `${progressPercent}%` }"></div>
            </div>
            <p class="text-xs text-neutral-400 text-center">
              {{ t('membership.next_tier', { amount: formatCurrency(profile.spent_to_next_tier), tier: profile.next_tier.name_vi }) }}
            </p>
          </div>
          
          <div v-if="profile.loyalty_rule" class="mt-4 pt-4 border-t border-neutral-700/50 text-xs text-neutral-400 text-center relative z-10">
            Earn rate: 1 pt / {{ formatCurrency(1 / profile.loyalty_rule.points_per_vnd) }} spent
          </div>
        </div>

        <!-- Stats Strip -->
        <div class="grid grid-cols-3 gap-4">
          <div class="bg-neutral-800/30 p-3 rounded-xl border border-neutral-800 text-center">
            <p class="text-xs text-neutral-500 mb-1">Total Spent</p>
            <p class="text-sm font-semibold text-neutral-200">{{ formatCurrency(profile.customer.total_spent) }}</p>
          </div>
          <div class="bg-neutral-800/30 p-3 rounded-xl border border-neutral-800 text-center">
            <p class="text-xs text-neutral-500 mb-1">Total Visits</p>
            <p class="text-sm font-semibold text-neutral-200">{{ profile.customer.total_visits }}</p>
          </div>
          <div class="bg-neutral-800/30 p-3 rounded-xl border border-neutral-800 text-center">
            <p class="text-xs text-neutral-500 mb-1">Last Visit</p>
            <p class="text-sm font-semibold text-neutral-200">{{ formatDate(profile.customer.last_visit_at) || '-' }}</p>
          </div>
        </div>

        <!-- Transaction History -->
        <div>
          <h4 class="text-sm font-semibold text-neutral-300 mb-4">{{ t('membership.history') }}</h4>
          <div class="space-y-4 relative before:absolute before:inset-y-0 before:left-[15px] before:w-px before:bg-neutral-800">
            <div 
              v-for="tx in profile.recent_transactions" 
              :key="tx.id"
              class="relative pl-10"
            >
              <!-- Icon -->
              <div 
                class="absolute left-0 top-1 w-8 h-8 rounded-full border border-neutral-800 bg-neutral-900 flex items-center justify-center z-10"
                :class="{
                  'text-green-400': tx.type === 'EARN',
                  'text-amber-400': tx.type === 'REDEEM',
                  'text-neutral-400': tx.type === 'ADJUST_ADD' || tx.type === 'ADJUST_SUB'
                }"
              >
                <ArrowUp v-if="tx.type === 'EARN' || tx.type === 'ADJUST_ADD'" class="w-4 h-4" />
                <ArrowDown v-else-if="tx.type === 'REDEEM' || tx.type === 'ADJUST_SUB'" class="w-4 h-4" />
                <Pencil v-else class="w-4 h-4" />
              </div>

              <!-- Content -->
              <div class="bg-neutral-800/30 border border-neutral-800 rounded-lg p-3">
                <div class="flex justify-between items-start mb-1">
                  <p class="text-sm font-medium" :class="{
                    'text-green-400': tx.type === 'EARN',
                    'text-amber-400': tx.type === 'REDEEM',
                    'text-neutral-300': tx.type === 'ADJUST_ADD' || tx.type === 'ADJUST_SUB'
                  }">
                    {{ tx.type === 'EARN' || tx.type === 'ADJUST_ADD' ? '+' : '-' }}{{ formatPoints(tx.points) }} pts
                  </p>
                  <span class="text-xs text-neutral-500">{{ formatDate(tx.created_at) }}</span>
                </div>
                <p class="text-xs text-neutral-400">{{ tx.description || '-' }}</p>
                <p class="text-xs text-neutral-600 mt-1">Balance: {{ formatPoints(tx.balance_after) }}</p>
              </div>
            </div>
            
            <div v-if="!profile.recent_transactions?.length" class="text-center text-neutral-500 text-sm py-4">
              No transactions yet.
            </div>
          </div>
        </div>

      </div>
    </div>

    <!-- Adjust Points Modal -->
    <div v-if="showAdjustModal" class="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/80">
      <div class="bg-neutral-900 border border-neutral-800 rounded-xl w-full max-w-sm overflow-hidden shadow-2xl">
        <div class="p-4 border-b border-neutral-800 flex justify-between items-center bg-neutral-800/50">
          <h3 class="text-lg font-medium text-white">Adjust Points</h3>
          <button @click="showAdjustModal = false" class="text-neutral-400 hover:text-white">
            <X class="w-5 h-5" />
          </button>
        </div>
        <div class="p-5 space-y-4">
          <div>
            <label class="block text-sm text-neutral-400 mb-1">Action</label>
            <div class="flex gap-2">
              <button 
                @click="adjustForm.type = 'ADJUST_ADD'"
                class="flex-1 py-2 rounded-lg border text-sm font-medium transition-colors"
                :class="adjustForm.type === 'ADJUST_ADD' ? 'bg-green-500/20 border-green-500 text-green-400' : 'border-neutral-700 text-neutral-400 hover:bg-neutral-800'"
              >
                {{ t('membership.adjust_add') }}
              </button>
              <button 
                @click="adjustForm.type = 'ADJUST_SUB'"
                class="flex-1 py-2 rounded-lg border text-sm font-medium transition-colors"
                :class="adjustForm.type === 'ADJUST_SUB' ? 'bg-red-500/20 border-red-500 text-red-400' : 'border-neutral-700 text-neutral-400 hover:bg-neutral-800'"
              >
                {{ t('membership.adjust_sub') }}
              </button>
            </div>
          </div>
          <div>
            <label class="block text-sm text-neutral-400 mb-1">{{ t('membership.points') }}</label>
            <input 
              v-model.number="adjustForm.points" 
              type="number" 
              min="1"
              class="w-full bg-neutral-950 border border-neutral-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-amber-500"
            />
          </div>
          <div>
            <label class="block text-sm text-neutral-400 mb-1">{{ t('membership.reason') }}</label>
            <input 
              v-model="adjustForm.reason" 
              type="text" 
              class="w-full bg-neutral-950 border border-neutral-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-amber-500"
            />
          </div>
        </div>
        <div class="p-4 border-t border-neutral-800 flex justify-end gap-2 bg-neutral-800/30">
          <button @click="showAdjustModal = false" class="px-4 py-2 text-sm text-neutral-300 hover:bg-neutral-800 rounded-lg transition-colors">Cancel</button>
          <button 
            @click="handleAdjustSubmit" 
            :disabled="adjustLoading || adjustForm.points <= 0"
            class="px-4 py-2 text-sm bg-amber-600 hover:bg-amber-500 disabled:opacity-50 text-white rounded-lg transition-colors font-medium"
          >
            {{ adjustLoading ? 'Saving...' : 'Confirm' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
