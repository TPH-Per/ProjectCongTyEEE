import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch, throwBranchGuard } from '@/composables/useBranch'
import { useAuth } from '@/composables/useAuth'

export interface MembershipTier {
  id: string
  branch_id: string | null
  name_vi: string
  name_en: string | null
  name_ja: string | null
  min_spent: number
  discount_percent: number
  points_multiplier: number
  color: string
  icon_name: string
  sort_order: number
}

export interface LoyaltyRule {
  id: string
  branch_id: string | null
  points_per_vnd: number
  vnd_per_point: number
  min_redeem_points: number
  max_redeem_percent: number
  is_active: boolean
}

export interface MembershipTierPatch {
  name_vi?: string
  name_en?: string | null
  name_ja?: string | null
  min_spent?: number
  discount_percent?: number
  points_multiplier?: number
  color?: string
  icon_name?: string
  sort_order?: number
}

export function useMembership() {
  const tiers = ref<MembershipTier[]>([])
  const rules = ref<LoyaltyRule | null>(null)
  const { activeBranchId } = useBranch()
  const { profile } = useAuth()

  // Fetch all tier configurations
  async function fetchTiers() {
    if (!activeBranchId.value) throw new Error('No active branch selected')
    const { data, error } = await supabase
      .from('membership_tiers')
      .select('*')
      .or(`branch_id.eq.${activeBranchId.value},branch_id.is.null`)
      .order('sort_order', { ascending: true })
    if (error) throw error
    tiers.value = data as any[]
  }

  // Admin: update tier thresholds
  async function updateTier(tierId: string, patch: Partial<MembershipTierPatch>) {
    const { data, error } = await supabase
      .from('membership_tiers')
      .update(patch)
      .eq('id', tierId)
      .select()
      .single()
    if (error) throw error
    const i = tiers.value.findIndex(t => t.id === tierId)
    if (i >= 0) tiers.value[i] = data as any
    return data as any
  }

  // Fetch loyalty rules
  async function fetchRules() {
    if (!activeBranchId.value) throw new Error('No active branch selected')
    const { data, error } = await supabase
      .from('loyalty_rules')
      .select('*')
      .or(`branch_id.eq.${activeBranchId.value},branch_id.is.null`)
      .order('branch_id', { ascending: false, nullsFirst: false })
      .limit(1)
      .maybeSingle()
    if (error) throw error
    rules.value = data as any
  }

  // Admin: update earn/redeem rates
  async function updateRules(patch: Partial<LoyaltyRule>) {
    if (!activeBranchId.value) throw new Error('No active branch selected')
    const { error } = await supabase
      .from('loyalty_rules')
      .update({ ...patch, updated_at: new Date().toISOString() })
      .or(`branch_id.eq.${activeBranchId.value}`)
    if (error) throw error
    if (rules.value) Object.assign(rules.value, patch)
  }

  // Calculate earn preview (client-side, for checkout UI)
  function previewEarnPoints(orderAmount: number, tierMultiplier = 1.0): number {
    if (!rules.value) return 0
    return Math.floor(orderAmount * rules.value.points_per_vnd * tierMultiplier)
  }

  // Calculate redeem discount (client-side)
  function previewRedeemValue(points: number): number {
    if (!rules.value) return 0
    return points * rules.value.vnd_per_point
  }

  // Earn points after checkout
  async function earnPoints(customerId: string, orderId: string, orderAmount: number) {
    if (!activeBranchId.value) throw new Error('No active branch selected')
    const { data, error } = await supabase.rpc('earn_points_for_order', {
      p_customer_id: customerId,
      p_branch_id: activeBranchId.value,
      p_order_id: orderId,
      p_order_amount: orderAmount
    })
    if (error) throw error
    return data as any
  }

  // Redeem points during checkout
  async function redeemPoints(customerId: string, points: number, orderId?: string) {
    if (!activeBranchId.value) throw new Error('No active branch selected')
    const { data, error } = await supabase.rpc('redeem_points', {
      p_customer_id: customerId,
      p_branch_id: activeBranchId.value,
      p_points: points,
      p_order_id: orderId ?? null
    })
    if (error) {
      if (error.message.includes('P0022')) throw new Error('INSUFFICIENT_POINTS')
      if (error.message.includes('P0021')) throw new Error('BELOW_MIN_REDEEM')
      throw error
    }
    return data as any
  }

  // Admin: manual points adjustment
  async function adjustPoints(customerId: string, type: 'ADJUST_ADD' | 'ADJUST_SUB', points: number, reason: string) {
    if (!activeBranchId.value) throw new Error('No active branch selected')
    const { data, error } = await supabase.rpc('adjust_points', {
      p_customer_id: customerId,
      p_branch_id: activeBranchId.value,
      p_type: type,
      p_points: points,
      p_reason: reason,
      p_admin_id: profile.value?.id
    })
    if (error) throw error
    return data as any
  }

  // Computed
  const tierById = computed(() =>
    Object.fromEntries(tiers.value.map(t => [t.id, t]))
  )

  return {
    tiers,
    rules,
    tierById,
    fetchTiers,
    updateTier,
    fetchRules,
    updateRules,
    previewEarnPoints,
    previewRedeemValue,
    earnPoints,
    redeemPoints,
    adjustPoints
  }
}
