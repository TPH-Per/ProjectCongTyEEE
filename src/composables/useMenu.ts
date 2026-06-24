import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useBranch } from './useBranch'
import type { MenuCategory, MenuItem, Package as PackageRow } from '@/types/database'

export function useMenu() {
  const { activeBranchId } = useBranch()
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function getCategories(): Promise<MenuCategory[]> {
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('menu_items')
      .select('category')
      .eq('branch_id', activeBranchId.value!)
      .eq('is_available', true)
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    const unique = [...new Set((data || []).map((i: any) => i.category))]
    return unique.map(c => ({
      id: c,
      branch_id: activeBranchId.value!,
      name: c,
      is_active: true,
      sort_order: 1
    })) as MenuCategory[]
  }

  async function getItems(categoryId?: string): Promise<MenuItem[]> {
    loading.value = true
    error.value = null
    let q = supabase
      .from('menu_items')
      .select('*')
      .eq('branch_id', activeBranchId.value!)
      .eq('is_available', true)
      .order('name')
    if (categoryId) q = q.eq('category', categoryId)
    const { data, error: err } = await q
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    return (data ?? []) as MenuItem[]
  }

  async function getPackages(): Promise<PackageRow[]> {
    loading.value = true
    error.value = null
    const { data, error: err } = await supabase
      .from('packages')
      .select('*')
      .eq('branch_id', activeBranchId.value!)
      .eq('is_active', true)
      .order('name')
    loading.value = false
    if (err) {
      error.value = err.message
      throw err
    }
    return (data ?? []) as PackageRow[]
  }

  async function upsertItem(item: Partial<MenuItem>): Promise<MenuItem> {
    const payload = { ...item, branch_id: activeBranchId.value }
    const { data, error: err } = await supabase
      .from('menu_items')
      .upsert(payload)
      .select('*')
      .single<MenuItem>()
    if (err) throw err
    return data!
  }

  return { loading, error, getCategories, getItems, getPackages, upsertItem }
}
