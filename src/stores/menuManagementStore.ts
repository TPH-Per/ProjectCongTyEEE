// File: src/stores/menuManagementStore.ts
// ─────────────────────────────────────────────────────────────────────────────
// Pinia Setup Store for the Menu Management module.
//
// Holds reactive copies of the normalized mock data (deep-cloned so the
// original arrays in mockMenuData.ts are never mutated). Provides computed
// getters for filtered lists and action functions for CRUD + reordering.
//
// Status changes (sold-out toggle, active/lock toggle) are broadcast via
// window.dispatchEvent so the POS order screen can react in real time.
// ─────────────────────────────────────────────────────────────────────────────

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import {
  mockCategories,
  mockSubCategories,
  mockItems,
  type MenuCategory,
  type MenuSubCategory,
  type MenuItem,
} from '@/data/mockMenuData'

let _idCounter = 100
const genId = (prefix: string) => `${prefix}-${++_idCounter}`

export const useMenuManagementStore = defineStore('menuManagement', () => {
  // ── State (deep-cloned so originals stay pristine) ──────────────────────
  const categories = ref<MenuCategory[]>(JSON.parse(JSON.stringify(mockCategories)))
  const subCategories = ref<MenuSubCategory[]>(JSON.parse(JSON.stringify(mockSubCategories)))
  const items = ref<MenuItem[]>(JSON.parse(JSON.stringify(mockItems)))

  // ── Getters ─────────────────────────────────────────────────────────────

  /** All categories sorted by sort_order (including inactive). */
  const sortedCategories = computed(() =>
    [...categories.value].sort((a, b) => a.sort_order - b.sort_order),
  )

  /** Only active categories, sorted. */
  const activeCategories = computed(() =>
    sortedCategories.value.filter((c) => c.is_active),
  )

  function subCategoriesByCategory(categoryId: string): MenuSubCategory[] {
    return subCategories.value
      .filter((sc) => sc.category_id === categoryId)
      .sort((a, b) => a.sort_order - b.sort_order)
  }

  /** Items for a specific category + optional sub-category filter. */
  function itemsByCategory(
    categoryId: string,
    subCategoryId: string | null = undefined,
  ): MenuItem[] {
    return items.value
      .filter((item) => {
        if (item.category_id !== categoryId) return false
        if (subCategoryId === undefined) return true
        if (subCategoryId === null) return item.sub_category_id === null
        return item.sub_category_id === subCategoryId
      })
      .sort((a, b) => a.sort_order - b.sort_order)
  }

  function itemCountByCategory(categoryId: string): number {
    return items.value.filter((i) => i.category_id === categoryId).length
  }

  function itemCountBySubCategory(subCategoryId: string): number {
    return items.value.filter((i) => i.sub_category_id === subCategoryId).length
  }

  function subCategoryCountByCategory(categoryId: string): number {
    return subCategories.value.filter((sc) => sc.category_id === categoryId).length
  }

  function getCategoryById(id: string): MenuCategory | undefined {
    return categories.value.find((c) => c.id === id)
  }

  function getSubCategoryById(id: string): MenuSubCategory | undefined {
    return subCategories.value.find((sc) => sc.id === id)
  }

  function getItemById(id: string): MenuItem | undefined {
    return items.value.find((i) => i.id === id)
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /** Broadcast item status change so the POS order screen can react. */
  function broadcastItemStatus(itemId: string): void {
    const item = getItemById(itemId)
    if (!item) return
    window.dispatchEvent(
      new CustomEvent('menu:item-status-changed', {
        detail: {
          id: item.id,
          name: item.name,
          is_active: item.is_active,
          is_sold_out: item.is_sold_out,
        },
      }),
    )
  }

  // ── Item Actions ─────────────────────────────────────────────────────────

  function addItem(data: Omit<MenuItem, 'id'>): MenuItem {
    const newItem: MenuItem = { ...data, id: genId('item') }
    items.value.push(newItem)
    broadcastItemStatus(newItem.id)
    return newItem
  }

  function updateItem(id: string, updates: Partial<MenuItem>): MenuItem | null {
    const idx = items.value.findIndex((i) => i.id === id)
    if (idx === -1) return null
    items.value[idx] = { ...items.value[idx], ...updates }
    broadcastItemStatus(id)
    return items.value[idx]
  }

  /** Soft-delete: flip is_active to false (never removes from array). */
  function softDeleteItem(id: string): void {
    const item = getItemById(id)
    if (!item) return
    item.is_active = false
    broadcastItemStatus(id)
  }

  /** Duplicate an item — name gets "(Bản sao)", SKU gets "-COPY", starts inactive. */
  function copyItem(id: string): MenuItem | null {
    const original = getItemById(id)
    if (!original) return null
    const siblings = items.value.filter((i) => i.category_id === original.category_id)
    const copy: MenuItem = {
      ...JSON.parse(JSON.stringify(original)),
      id: genId('item'),
      name: `${original.name} (Bản sao)`,
      sku: `${original.sku}-COPY`,
      barcode: '',
      is_active: false,
      is_sold_out: false,
      sort_order: siblings.length + 1,
    }
    items.value.push(copy)
    return copy
  }

  function toggleSoldOut(id: string): void {
    const item = getItemById(id)
    if (!item) return
    item.is_sold_out = !item.is_sold_out
    broadcastItemStatus(id)
  }

  function toggleItemActive(id: string): void {
    const item = getItemById(id)
    if (!item) return
    item.is_active = !item.is_active
    broadcastItemStatus(id)
  }

  // ── Category Actions ────────────────────────────────────────────────────

  function addCategory(data: Omit<MenuCategory, 'id' | 'sort_order'>): MenuCategory {
    const maxOrder = Math.max(0, ...categories.value.map((c) => c.sort_order))
    const newCat: MenuCategory = { ...data, id: genId('cat'), sort_order: maxOrder + 1 }
    categories.value.push(newCat)
    return newCat
  }

  function addSubCategory(data: Omit<MenuSubCategory, 'id' | 'sort_order'>): MenuSubCategory {
    const siblings = subCategories.value.filter((sc) => sc.category_id === data.category_id)
    const maxOrder = Math.max(0, ...siblings.map((sc) => sc.sort_order))
    const newSub: MenuSubCategory = { ...data, id: genId('sub'), sort_order: maxOrder + 1 }
    subCategories.value.push(newSub)
    return newSub
  }

  /**
   * Delete category — validates that it has no items or sub-categories.
   * Returns { success, message }.
   */
  function deleteCategory(id: string): { success: boolean; message: string } {
    const itemCount = itemCountByCategory(id)
    const subCount = subCategoryCountByCategory(id)
    if (itemCount > 0 || subCount > 0) {
      const parts: string[] = []
      if (itemCount > 0) parts.push(`${itemCount} món`)
      if (subCount > 0) parts.push(`${subCount} danh mục con`)
      return {
        success: false,
        message: `Không thể xóa! Danh mục vẫn còn ${parts.join(' và ')}. Vui lòng di chuyển hoặc xóa trước khi xóa danh mục.`,
      }
    }
    const cat = getCategoryById(id)
    if (cat) cat.is_active = false
    return { success: true, message: 'Đã ẩn danh mục.' }
  }

  function deleteSubCategory(id: string): { success: boolean; message: string } {
    const itemCount = itemCountBySubCategory(id)
    if (itemCount > 0) {
      return {
        success: false,
        message: `Không thể xóa! Danh mục con vẫn còn ${itemCount} món. Vui lòng di chuyển hoặc xóa trước.`,
      }
    }
    const sub = getSubCategoryById(id)
    if (sub) sub.is_active = false
    return { success: true, message: 'Đã ẩn danh mục con.' }
  }

  function reorderCategories(orderedIds: string[]): void {
    orderedIds.forEach((id, index) => {
      const cat = categories.value.find((c) => c.id === id)
      if (cat) cat.sort_order = index + 1
    })
  }

  function reorderSubCategories(categoryId: string, orderedIds: string[]): void {
    orderedIds.forEach((id, index) => {
      const sub = subCategories.value.find((sc) => sc.id === id)
      if (sub && sub.category_id === categoryId) sub.sort_order = index + 1
    })
  }

  function toggleCategoryPosVisibility(id: string): void {
    const cat = getCategoryById(id)
    if (cat) cat.is_visible_on_pos = !cat.is_visible_on_pos
  }

  function toggleCategoryActive(id: string): void {
    const cat = getCategoryById(id)
    if (cat) cat.is_active = !cat.is_active
  }

  // ── Export ──────────────────────────────────────────────────────────────
  return {
    // state
    categories,
    subCategories,
    items,
    // getters
    sortedCategories,
    activeCategories,
    subCategoriesByCategory,
    itemsByCategory,
    itemCountByCategory,
    itemCountBySubCategory,
    subCategoryCountByCategory,
    getCategoryById,
    getSubCategoryById,
    getItemById,
    // item actions
    addItem,
    updateItem,
    softDeleteItem,
    copyItem,
    toggleSoldOut,
    toggleItemActive,
    // category actions
    addCategory,
    addSubCategory,
    deleteCategory,
    deleteSubCategory,
    reorderCategories,
    reorderSubCategories,
    toggleCategoryPosVisibility,
    toggleCategoryActive,
  }
})
