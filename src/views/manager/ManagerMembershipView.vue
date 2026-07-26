<template>
  <div class="space-y-6">
    <!-- Page Header -->
    <div class="flex items-start justify-between">
      <div>
        <h1 class="text-2xl font-black text-[hsl(var(--foreground))] tracking-tight">{{ $t('membership.title', 'Hội Viên') }}</h1>
        <p class="text-sm text-[hsl(var(--muted-foreground))] mt-1">Cấu hình hạng thành viên và quy tắc tích/đổi điểm</p>
      </div>
    </div>

    <!-- Tabs -->
    <div class="flex gap-4 border-b border-[hsl(var(--border))]">
      <button 
        class="px-4 py-2 text-sm font-bold border-b-2 transition-colors"
        :class="activeTab === 'tiers' ? 'border-[hsl(var(--primary))] text-[hsl(var(--primary))]' : 'border-transparent text-[hsl(var(--muted-foreground))] hover:text-[hsl(var(--foreground))]'"
        @click="activeTab = 'tiers'"
      >
        Membership Tiers
      </button>
      <button 
        class="px-4 py-2 text-sm font-bold border-b-2 transition-colors"
        :class="activeTab === 'rules' ? 'border-[hsl(var(--primary))] text-[hsl(var(--primary))]' : 'border-transparent text-[hsl(var(--muted-foreground))] hover:text-[hsl(var(--foreground))]'"
        @click="activeTab = 'rules'"
      >
        Earn & Redeem Rules
      </button>
    </div>

    <!-- Tiers Tab -->
    <div v-if="activeTab === 'tiers'" class="space-y-4">
      <div v-if="!tiers.length" class="text-center py-8 text-gray-500">
        {{ $t('common.loading', 'Đang tải...') }}
      </div>
      <div 
        v-for="tier in editableTiers" 
        :key="tier.id" 
        class="kawaii-card p-5 relative overflow-hidden transition-shadow hover:shadow-md"
        :style="{ borderLeftColor: tier.color, borderLeftWidth: '6px' }"
      >
        <div class="flex items-start gap-4">
          <div class="w-12 h-12 rounded-full flex items-center justify-center text-white shrink-0" :style="{ backgroundColor: tier.color }">
            <component :is="getIcon(tier.icon_name)" class="w-6 h-6" />
          </div>
          <div class="flex-1 grid grid-cols-1 md:grid-cols-2 gap-4">
            
            <div class="space-y-3">
              <!-- Names -->
              <div>
                <label class="block text-xs font-bold text-gray-500 mb-1">Tên Hạng (VI / EN / JA)</label>
                <div class="flex gap-2">
                  <input v-model="tier.name_vi" @blur="handleSaveTier(tier)" class="kawaii-input py-1 text-sm flex-1" placeholder="VI" />
                  <input v-model="tier.name_en" @blur="handleSaveTier(tier)" class="kawaii-input py-1 text-sm flex-1" placeholder="EN" />
                  <input v-model="tier.name_ja" @blur="handleSaveTier(tier)" class="kawaii-input py-1 text-sm flex-1" placeholder="JA" />
                </div>
              </div>
              
              <!-- Color & Icon -->
              <div class="flex gap-4">
                <div class="flex-1">
                  <label class="block text-xs font-bold text-gray-500 mb-1">Mã Màu (Color)</label>
                  <div class="flex items-center gap-2">
                    <input type="color" v-model="tier.color" @blur="handleSaveTier(tier)" class="w-8 h-8 rounded cursor-pointer border-0 p-0" />
                    <input v-model="tier.color" @blur="handleSaveTier(tier)" class="kawaii-input py-1 text-sm flex-1 uppercase font-mono" />
                  </div>
                </div>
                <div class="flex-1">
                  <label class="block text-xs font-bold text-gray-500 mb-1">Biểu tượng (Icon)</label>
                  <select v-model="tier.icon_name" @change="handleSaveTier(tier)" class="kawaii-input py-1 text-sm w-full">
                    <option value="award">Award (Đồng)</option>
                    <option value="shield">Shield (Bạc)</option>
                    <option value="star">Star (Vàng)</option>
                    <option value="gem">Gem (Kim Cương)</option>
                  </select>
                </div>
              </div>
            </div>

            <div class="space-y-3">
              <!-- Conditions & Benefits -->
              <div>
                <label class="block text-xs font-bold text-gray-500 mb-1">Ngưỡng chi tiêu tối thiểu (VND)</label>
                <input type="number" v-model.number="tier.min_spent" @blur="handleSaveTier(tier)" class="kawaii-input py-1 text-sm w-full" />
              </div>
              
              <div class="flex gap-4">
                <div class="flex-1">
                  <label class="block text-xs font-bold text-gray-500 mb-1">Tỷ lệ giảm giá (%)</label>
                  <input type="number" step="0.1" v-model.number="tier.discount_percent" @blur="handleSaveTier(tier)" class="kawaii-input py-1 text-sm w-full" />
                </div>
                <div class="flex-1">
                  <label class="block text-xs font-bold text-gray-500 mb-1">Hệ số tích điểm</label>
                  <input type="number" step="0.1" v-model.number="tier.points_multiplier" @blur="handleSaveTier(tier)" class="kawaii-input py-1 text-sm w-full" />
                </div>
              </div>
            </div>

          </div>
        </div>
        
        <div class="mt-4 pt-3 border-t border-[hsl(var(--border))] text-sm text-[hsl(var(--muted-foreground))]">
          <strong>Preview:</strong> Khách chi tiêu từ <strong :style="{ color: tier.color }">{{ (tier.min_spent || 0).toLocaleString() }}đ</strong> sẽ đạt hạng <strong :style="{ color: tier.color }">{{ tier.name_vi }}</strong>, được giảm <strong :style="{ color: tier.color }">{{ tier.discount_percent }}%</strong> trên hóa đơn và tích điểm hệ số <strong :style="{ color: tier.color }">{{ tier.points_multiplier }}x</strong>.
        </div>
      </div>
    </div>

    <!-- Rules Tab -->
    <div v-if="activeTab === 'rules'" class="kawaii-card p-6 max-w-2xl">
      <h3 class="font-bold text-lg text-[hsl(var(--foreground))] mb-6">Quy Tắc Tích & Đổi Điểm</h3>
      
      <div v-if="editableRules" class="space-y-5">
        <div>
          <label class="block text-sm font-bold text-[hsl(var(--foreground))] mb-1">Tỷ lệ tích điểm (Points per VND)</label>
          <p class="text-xs text-gray-500 mb-2">Ví dụ: 0.001 nghĩa là 1 điểm cho mỗi 1,000đ chi tiêu.</p>
          <input type="number" step="0.0001" v-model.number="editableRules.points_per_vnd" class="kawaii-input w-full" />
        </div>

        <div>
          <label class="block text-sm font-bold text-[hsl(var(--foreground))] mb-1">Giá trị đổi điểm (VND per Point)</label>
          <p class="text-xs text-gray-500 mb-2">Ví dụ: 1000 nghĩa là 1 điểm đổi được 1,000đ giảm giá.</p>
          <input type="number" v-model.number="editableRules.vnd_per_point" class="kawaii-input w-full" />
        </div>

        <div>
          <label class="block text-sm font-bold text-[hsl(var(--foreground))] mb-1">Số điểm tối thiểu để đổi</label>
          <p class="text-xs text-gray-500 mb-2">Khách hàng cần có ít nhất số điểm này mới được sử dụng tính năng đổi điểm.</p>
          <input type="number" v-model.number="editableRules.min_redeem_points" class="kawaii-input w-full" />
        </div>

        <div>
          <label class="block text-sm font-bold text-[hsl(var(--foreground))] mb-1">Tỷ lệ thanh toán tối đa bằng điểm (%)</label>
          <p class="text-xs text-gray-500 mb-2">Điểm tối đa có thể trả cho một hóa đơn. Ví dụ: 50 nghĩa là điểm thưởng chỉ thanh toán tối đa 50% giá trị bill.</p>
          <input type="number" step="1" v-model.number="editableRules.max_redeem_percent" class="kawaii-input w-full" />
        </div>

        <div class="pt-4 border-t border-[hsl(var(--border))]">
          <button @click="handleSaveRules" class="kawaii-btn-primary w-full py-3 text-sm font-bold" :disabled="savingRules">
            {{ savingRules ? $t('common.loading', 'Đang lưu...') : $t('common.save', 'Lưu Cài Đặt') }}
          </button>
        </div>
      </div>
      <div v-else class="text-center py-8 text-gray-500">
        {{ $t('common.loading', 'Đang tải...') }}
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { Award, Shield, Star, Gem } from 'lucide-vue-next'
import { useMembership } from '@/composables/useMembership'

const activeTab = ref<'tiers' | 'rules'>('tiers')
const { tiers, rules, fetchTiers, fetchRules, updateTier, updateRules } = useMembership()

const editableTiers = ref<any[]>([])
const editableRules = ref<any>(null)
const savingRules = ref(false)

const getIcon = (name: string) => {
  switch (name) {
    case 'shield': return Shield
    case 'star': return Star
    case 'gem': return Gem
    case 'award':
    default:
      return Award
  }
}

onMounted(async () => {
  await fetchTiers()
  await fetchRules()
})

watch(tiers, (newTiers) => {
  // Deep clone to allow editing without affecting global state until saved
  editableTiers.value = JSON.parse(JSON.stringify(newTiers))
}, { deep: true })

watch(rules, (newRules) => {
  if (newRules) {
    editableRules.value = { ...newRules }
  }
}, { deep: true })

async function handleSaveTier(tier: any) {
  try {
    await updateTier(tier.id, {
      name_vi: tier.name_vi,
      name_en: tier.name_en,
      name_ja: tier.name_ja,
      color: tier.color,
      icon_name: tier.icon_name,
      min_spent: tier.min_spent,
      discount_percent: tier.discount_percent,
      points_multiplier: tier.points_multiplier
    })
    // Optionally show a small toast or just rely on reactivity
  } catch (err: any) {
    alert('Lỗi khi lưu hạng: ' + err.message)
  }
}

async function handleSaveRules() {
  if (!editableRules.value) return
  try {
    savingRules.value = true
    await updateRules({
      points_per_vnd: editableRules.value.points_per_vnd,
      vnd_per_point: editableRules.value.vnd_per_point,
      min_redeem_points: editableRules.value.min_redeem_points,
      max_redeem_percent: editableRules.value.max_redeem_percent,
    })
    alert('Lưu quy tắc thành công!')
  } catch (err: any) {
    alert('Lỗi khi lưu quy tắc: ' + err.message)
  } finally {
    savingRules.value = false
  }
}
</script>
