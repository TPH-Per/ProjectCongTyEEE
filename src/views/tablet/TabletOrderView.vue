<template>
  <div class="flex-1 flex flex-col h-full overflow-hidden bg-[#111111]">

    <!-- Header -->
    <header class="h-20 bg-[#1e1e1e] border-b border-gray-800 flex items-center justify-between px-8 shrink-0">
      <div class="flex items-center gap-4">
        <div class="w-12 h-12 bg-red-600 rounded-xl flex items-center justify-center text-white font-bold text-xl">
          🐂
        </div>
        <div>
          <h2 class="text-xl font-bold text-white">{{ $t('tablet.order.table_t1_a4') }}</h2>
          <p class="text-sm text-gray-400">Premium Buffet 1380k + Drink A</p>
        </div>
      </div>
      
      <div class="flex items-center gap-6">
        <div class="bg-gray-800 rounded-full px-4 py-2 flex items-center gap-2">
          <span class="text-gray-400 font-medium">{{ $t('tablet.order.order_limit') }}</span>
          <span class="text-white font-bold"><span class="text-red-500">3</span> {{ $t('tablet.order.max_items') }}</span>
        </div>
        <button @click="submitOrder" :disabled="submitting" class="bg-red-600 hover:bg-red-700 text-white font-bold py-3 px-8 rounded-full text-lg shadow-[0_0_15px_rgba(220,38,38,0.5)] transition-all disabled:opacity-50 disabled:cursor-not-allowed">
          {{ submitting ? $t('tablet.order.sending') : $t('tablet.order.send_to_kitchen') }}
        </button>
      </div>
    </header>

    <!-- Main Content -->
    <div class="flex-1 flex overflow-hidden">
      <!-- Categories Sidebar -->
      <aside class="w-64 bg-[#1a1a1a] border-r border-gray-800 overflow-y-auto">
        <div class="p-4 space-y-2">
          <div class="text-xs font-bold text-gray-500 uppercase tracking-wider mb-4 px-4">Menu</div>
          <button v-for="cat in categories" :key="cat.id"
            @click="loadItems(cat.id)"
            :class="[
              'w-full text-left px-6 py-4 rounded-xl font-medium transition-colors mb-2',
              selectedCategoryId === cat.id 
                ? 'bg-red-600/20 text-red-500 font-bold border border-red-600/30'
                : 'text-gray-400 hover:bg-gray-800 hover:text-white bg-transparent border border-transparent'
            ]"
          >
            {{ cat.name }}
          </button>
        </div>
      </aside>

      <!-- Items Grid -->
      <main class="flex-1 overflow-y-auto p-8">
        <!-- Notice if flow is locked -->
        <div class="mb-6 bg-blue-900/30 border border-blue-800 rounded-xl p-4 flex items-start gap-3">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-blue-400 mt-0.5"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/></svg>
          <div>
            <h4 class="text-blue-400 font-bold text-sm">{{ $t('tablet.order.one_way_order_flow') }}</h4>
            <p class="text-gray-400 text-sm mt-1">{{ $t('tablet.order.please_select_items') }}</p>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
          <div v-for="item in items" :key="item.id" class="bg-[#1e1e1e] rounded-2xl border border-gray-800 overflow-hidden flex flex-col group hover:border-gray-600 transition-colors">
            <div class="h-48 bg-gray-800 relative">
              <img v-if="item.image_url" :src="item.image_url" :alt="item.name" class="w-full h-full object-cover" />
              <div v-else class="w-full h-full flex items-center justify-center text-gray-600">No Image</div>
            </div>
            <div class="p-5 flex-1 flex flex-col">
              <h3 class="text-lg font-bold text-white mb-1">{{ item.name }}</h3>
              <p class="text-sm text-gray-400 mb-4 flex-1">{{ item.description || '' }}</p>
              
              <div class="flex items-center justify-between mt-auto">
                <span class="text-red-500 font-bold">{{ item.price.toLocaleString() }}đ</span>
                <div class="flex items-center gap-3 bg-black rounded-full p-1 border border-gray-800">
                  <button @click="decrement(item)" :class="['w-8 h-8 rounded-full flex items-center justify-center transition-colors', cart[item.id] ? 'bg-gray-800 text-white hover:bg-gray-700' : 'bg-gray-800 text-gray-500 cursor-not-allowed']">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/></svg>
                  </button>
                  <span class="font-bold w-4 text-center">{{ cart[item.id] || 0 }}</span>
                  <button @click="increment(item)" class="w-8 h-8 rounded-full bg-red-600 flex items-center justify-center text-white hover:bg-red-700 transition-colors shadow-lg shadow-red-600/30">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
    
    <!-- Footer actions -->
    <footer class="bg-black border-t border-gray-800 p-4 flex justify-between items-center shrink-0">
      <button class="text-gray-400 hover:text-white px-6 py-2 flex items-center gap-2 font-medium">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/></svg>
        {{ $t('tablet.order.need_support') }}
      </button>
      
      <button class="bg-gray-800 hover:bg-gray-700 text-white px-8 py-3 rounded-xl font-bold flex items-center gap-2 border border-gray-700 transition-colors">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12V7H5a2 2 0 0 1 0-4h14v4"/><path d="M3 5v14a2 2 0 0 0 2 2h16v-5"/><path d="M18 12a2 2 0 0 0 0 4h4v-4Z"/></svg>
        {{ $t('tablet.order.request_payment') }}
      </button>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { DEFAULT_BRANCH_ID } from '@/lib/branch-constants'
import type { MenuCategory, MenuItem } from '@/types/database'

import Swal from 'sweetalert2'

const { t } = useI18n()
const { branchId } = useAuth()

const submitting = ref(false)
const categories = ref<MenuCategory[]>([])
const items = ref<MenuItem[]>([])
const selectedCategoryId = ref<string | null>(null)
const cart = ref<Record<string, number>>({})
const loadingItems = ref(false)

// Assume order_id is in localStorage, or provide mock
const orderId = ref(localStorage.getItem('tablet_order_id') || 'mock-order-id-for-tablet')
const activeBranchId = branchId.value || localStorage.getItem('branch_id') || DEFAULT_BRANCH_ID

onMounted(async () => {
  await loadCategories()
})

async function loadCategories() {
  const { data, error } = await supabase
    .from('menu_categories')
    .select('*')
    .eq('branch_id', activeBranchId)
    .eq('is_active', true)
    .order('sort_order')

  if (!error && data) {
    categories.value = data as MenuCategory[]

    if (categories.value.length > 0) {
      await loadItems(categories.value[0].id)
    }
  }
}

async function loadItems(categoryId: string) {
  loadingItems.value = true
  selectedCategoryId.value = categoryId

  const { data, error } = await supabase
    .from('menu_items')
    .select('*, menu_categories(name)')
    .eq('branch_id', activeBranchId)
    .eq('is_available', true)
    .eq('category_id', categoryId)
    .order('name')

  if (!error) {
    items.value = (data ?? []) as MenuItem[]
  }

  loadingItems.value = false
}

function increment(item: MenuItem) {
  cart.value[item.id] = (cart.value[item.id] || 0) + 1
}

function decrement(item: MenuItem) {
  if (cart.value[item.id] > 0) {
    cart.value[item.id]--
    if (cart.value[item.id] === 0) delete cart.value[item.id]
  }
}

async function submitOrder() {
  const itemIds = Object.keys(cart.value)
  if (itemIds.length === 0) return

  submitting.value = true

  try {
    for (const itemId of itemIds) {
      const qty = cart.value[itemId]
      if (qty > 0) {
        const { error } = await supabase.functions.invoke('add-order-item', {
          body: {
            orderId: orderId.value,
            menuItemId: itemId,
            quantity: qty
          }
        })
        if (error) throw error
      }
    }

    cart.value = {}
    Swal.fire(t('tablet.order.success'), t('tablet.order.sent_to_kitchen'), 'success')
  } catch (err) {
    console.error(t('tablet.order.error_sending_order_log'), err)
    Swal.fire(t('tablet.order.error'), t('tablet.order.error_sending_order'), 'error')
  } finally {
    submitting.value = false
  }
}
</script>

