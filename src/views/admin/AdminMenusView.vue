<template>
  <div class="space-y-6 max-w-7xl mx-auto">

    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 tracking-tight">{{ t('auto_th_c___n___g_i_menu') }}</h1>
        <p class="text-sm text-gray-500 mt-1">{{ t('auto_qu_n_l__c_c_m_n__n__g_i_buffet') }}</p>
      </div>
      <div class="flex gap-3">
        <button @click="editMenuItem()" class="bg-white border border-gray-200 hover:bg-gray-50 text-gray-900 px-5 py-2.5 rounded-xl font-bold transition-colors text-sm shadow-sm">
          {{ t('add_new_item', 'Thêm Món Mới') }}
        </button>
        <button @click="editPackage()" class="bg-gray-900 hover:bg-black text-white px-5 py-2.5 rounded-xl font-bold transition-colors text-sm shadow-md">
          {{ t('add_new_package', 'Thêm Gói Menu') }}
        </button>
      </div>
    </div>

    <div v-if="loading" class="text-center py-8 text-gray-500">
      {{ t('loading', 'Đang tải...') }}
    </div>

    <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Left: Packages -->
      <div class="lg:col-span-1 space-y-6">
        <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
          <div class="p-4 border-b border-gray-100 bg-gray-50">
            <h3 class="font-bold text-gray-900">{{ t('auto_g_i_buffet___set_menu') }}</h3>
          </div>
          <div class="p-4 space-y-3">
            <div 
              v-for="pkg in packages" 
              :key="pkg.id"
              class="border p-3 rounded-xl hover:border-gray-300 transition-colors"
              :class="pkg.is_active ? 'border-gray-200 bg-white' : 'border-gray-200 bg-gray-50 opacity-60'"
            >
              <div class="flex justify-between items-start mb-1">
                <div>
                  <div class="font-bold text-gray-900">{{ pkg.name }}</div>
                  <div class="text-sm font-semibold text-gray-600">{{ pkg.price.toLocaleString() }}đ</div>
                </div>
                <div class="flex items-center gap-2">
                  <label class="flex items-center cursor-pointer">
                    <div class="relative">
                      <input type="checkbox" class="sr-only" :checked="pkg.is_active" @change="togglePackageActive(pkg)">
                      <div class="block w-10 h-6 rounded-full transition-colors" :class="pkg.is_active ? 'bg-green-500' : 'bg-gray-300'"></div>
                      <div class="dot absolute left-1 top-1 bg-white w-4 h-4 rounded-full transition-transform" :class="pkg.is_active ? 'transform translate-x-4' : ''"></div>
                    </div>
                  </label>
                  <button @click="editPackage(pkg)" class="text-blue-600 hover:text-blue-800 p-1">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/><path d="m15 5 4 4"/></svg>
                  </button>
                </div>
              </div>
            </div>
            <div v-if="packages.length === 0" class="text-sm text-gray-500 text-center py-4">
              {{ t('no_packages', 'Chưa có gói menu nào') }}
            </div>
          </div>
        </div>
      </div>

      <!-- Right: Menu Items -->
      <div class="lg:col-span-2">
        <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden flex flex-col h-full">
          <div class="p-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
            <div>
              <h3 class="font-bold text-gray-900 text-lg">{{ t('all_menu_items', 'Tất cả món ăn') }}</h3>
              <p class="text-xs text-gray-500 mt-1">{{ t('auto_c_c_m_n_hi_n_th__tr_n_tablet_c') }}</p>
            </div>
          </div>
          <div class="p-0 overflow-x-auto">
            <table class="w-full text-left text-sm">
              <thead class="bg-white text-gray-500 font-semibold border-b">
                <tr>
                  <th class="px-5 py-3 w-20">{{ t('available', 'Có sẵn') }}</th>
                  <th class="px-5 py-3">{{ t('auto_danh_m_c') }}</th>
                  <th class="px-5 py-3">{{ t('auto_t_n_m_n') }}</th>
                  <th class="px-5 py-3">{{ t('auto_gi__l_') }}</th>
                  <th class="px-5 py-3 text-right">{{ t('actions', 'Thao tác') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="item in menuItems" :key="item.id" class="hover:bg-gray-50 transition-colors" :class="!item.is_available ? 'opacity-60 bg-gray-50' : 'bg-white'">
                  <td class="px-5 py-3">
                    <label class="flex items-center cursor-pointer">
                      <div class="relative">
                        <input type="checkbox" class="sr-only" :checked="item.is_available" @change="toggleMenuItemAvailable(item)">
                        <div class="block w-8 h-5 rounded-full transition-colors" :class="item.is_available ? 'bg-green-500' : 'bg-gray-300'"></div>
                        <div class="dot absolute left-1 top-1 bg-white w-3 h-3 rounded-full transition-transform" :class="item.is_available ? 'transform translate-x-3' : ''"></div>
                      </div>
                    </label>
                  </td>
                  <td class="px-5 py-3 text-gray-500">{{ item.menu_categories?.name }}</td>
                  <td class="px-5 py-3 font-bold text-gray-900">{{ item.name }}</td>
                  <td class="px-5 py-3 text-gray-600">{{ item.price.toLocaleString() }}đ</td>
                  <td class="px-5 py-3 text-right">
                    <button @click="editMenuItem(item)" class="text-blue-600 hover:text-blue-800">
                      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/><path d="m15 5 4 4"/></svg>
                    </button>
                  </td>
                </tr>
                <tr v-if="menuItems.length === 0">
                  <td colspan="5" class="px-5 py-8 text-center text-gray-500">
                    {{ t('no_items', 'Chưa có món ăn nào') }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>

    <!-- Package Modal -->
    <div v-if="showPackageModal" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div class="bg-white rounded-2xl w-full max-w-md overflow-hidden shadow-xl">
        <div class="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50">
          <h3 class="font-bold text-lg text-gray-900">{{ editingPackage.id ? t('edit_package', 'Sửa gói menu') : t('add_new_package', 'Thêm Gói Menu') }}</h3>
          <button @click="showPackageModal = false" class="text-gray-400 hover:text-gray-600">&times;</button>
        </div>
        <form @submit.prevent="savePackage" class="p-6 space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('package_name', 'Tên gói') }}</label>
            <input v-model="editingPackage.name" required type="text" class="w-full border-gray-300 rounded-lg shadow-sm focus:border-blue-500 focus:ring-blue-500" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('package_type', 'Loại gói') }}</label>
            <select v-model="editingPackage.type" required class="w-full border-gray-300 rounded-lg shadow-sm focus:border-blue-500 focus:ring-blue-500">
              <option value="buffet">Buffet</option>
              <option value="set">Set Menu</option>
              <option value="drink">Drink</option>
              <option value="other">Other</option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('price', 'Giá tiền') }}</label>
            <input v-model="editingPackage.price" required type="number" min="0" class="w-full border-gray-300 rounded-lg shadow-sm focus:border-blue-500 focus:ring-blue-500" />
          </div>
          <div class="flex items-center gap-2 mt-4">
            <input v-model="editingPackage.is_active" type="checkbox" id="pkgActive" class="rounded text-blue-600 focus:ring-blue-500" />
            <label for="pkgActive" class="text-sm font-medium text-gray-700">{{ t('active', 'Đang hoạt động') }}</label>
          </div>
          <div class="pt-4 flex justify-end gap-3">
            <button type="button" @click="showPackageModal = false" class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50">
              {{ t('cancel', 'Hủy') }}
            </button>
            <button type="submit" class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700" :disabled="saving">
              {{ saving ? t('saving', 'Đang lưu...') : t('save', 'Lưu') }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Menu Item Modal -->
    <div v-if="showMenuItemModal" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div class="bg-white rounded-2xl w-full max-w-md overflow-hidden shadow-xl">
        <div class="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50">
          <h3 class="font-bold text-lg text-gray-900">{{ editingMenuItem.id ? t('edit_item', 'Sửa món ăn') : t('add_new_item', 'Thêm Món Mới') }}</h3>
          <button @click="showMenuItemModal = false" class="text-gray-400 hover:text-gray-600">&times;</button>
        </div>
        <form @submit.prevent="saveMenuItem" class="p-6 space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('item_name', 'Tên món') }}</label>
            <input v-model="editingMenuItem.name" required type="text" class="w-full border-gray-300 rounded-lg shadow-sm focus:border-blue-500 focus:ring-blue-500" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('category', 'Danh mục') }}</label>
            <select v-model="editingMenuItem.category_id" required class="w-full border-gray-300 rounded-lg shadow-sm focus:border-blue-500 focus:ring-blue-500">
              <option v-for="cat in categories" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('price', 'Giá tiền') }}</label>
            <input v-model="editingMenuItem.price" required type="number" min="0" class="w-full border-gray-300 rounded-lg shadow-sm focus:border-blue-500 focus:ring-blue-500" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('unit', 'Đơn vị tính') }}</label>
            <input v-model="editingMenuItem.unit" required type="text" class="w-full border-gray-300 rounded-lg shadow-sm focus:border-blue-500 focus:ring-blue-500" :placeholder="t('auto_ph_n_a_kg', 'phần, đĩa, kg...')" />
          </div>
          <div class="flex items-center gap-2 mt-4">
            <input v-model="editingMenuItem.is_available" type="checkbox" id="itemAvailable" class="rounded text-blue-600 focus:ring-blue-500" />
            <label for="itemAvailable" class="text-sm font-medium text-gray-700">{{ t('available', 'Có sẵn') }}</label>
          </div>
          <div class="pt-4 flex justify-end gap-3">
            <button type="button" @click="showMenuItemModal = false" class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50">
              {{ t('cancel', 'Hủy') }}
            </button>
            <button type="submit" class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700" :disabled="saving">
              {{ saving ? t('saving', 'Đang lưu...') : t('save', 'Lưu') }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/composables/useAuth';
import type { Package, MenuItem, PackageType, MenuCategory } from '@/types/database';
import Swal from 'sweetalert2';

const { t } = useI18n();
const { branchId } = useAuth();

const packages = ref<Package[]>([]);
const menuItems = ref<MenuItem[]>([]);
const categories = ref<MenuCategory[]>([]);
const loading = ref(false);
const saving = ref(false);

const fetchMenus = async () => {
  if (!branchId.value) return;
  const bid = branchId.value;
  loading.value = true;
  try {
    const [pkgRes, itemRes, catRes] = await Promise.all([
      supabase.from('packages').select('*').eq('branch_id', bid).order('name'),
      supabase.from('menu_items').select('*, menu_categories(name)').eq('branch_id', bid).order('category_id'),
      supabase.from('menu_categories').select('*').eq('branch_id', bid).eq('is_active', true).order('sort_order')
    ]);
    if (pkgRes.error) throw pkgRes.error;
    if (itemRes.error) throw itemRes.error;
    if (catRes.error) throw catRes.error;

    packages.value = pkgRes.data || [];
    menuItems.value = itemRes.data || [];
    categories.value = catRes.data || [];
  } catch (err: any) {
    console.error('Error fetching menus:', err);
    Swal.fire('Lỗi', 'Không thể tải danh sách menu: ' + err.message, 'error');
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  fetchMenus();
});

// Package Modal
const showPackageModal = ref(false);
const editingPackage = ref<Partial<Package>>({});

const editPackage = (pkg?: Package) => {
  if (pkg) {
    editingPackage.value = { ...pkg };
  } else {
    editingPackage.value = { 
      name: '', 
      type: 'buffet' as PackageType, 
      price: 0, 
      is_active: true, 
      branch_id: branchId.value,
      i18n_name: { vi: '', en: '', ja: '' },
      items_included: [],
      metadata: {}
    };
  }
  showPackageModal.value = true;
};

const savePackage = async () => {
  saving.value = true;
  try {
    if (editingPackage.value.id) {
      const { error } = await supabase.from('packages')
        .update({
          name: editingPackage.value.name,
          type: editingPackage.value.type,
          price: editingPackage.value.price,
          is_active: editingPackage.value.is_active
        })
        .eq('id', editingPackage.value.id);
      if (error) throw error;
    } else {
      const { error } = await supabase.from('packages').insert([{
        ...editingPackage.value,
        branch_id: branchId.value
      }]);
      if (error) throw error;
    }
    showPackageModal.value = false;
    await fetchMenus();
  } catch (e) {
    console.error('Error saving package:', e);
  } finally {
    saving.value = false;
  }
};

// Menu Item Modal
const showMenuItemModal = ref(false);
const editingMenuItem = ref<Partial<MenuItem>>({});

const editMenuItem = (item?: MenuItem) => {
  if (item) {
    editingMenuItem.value = { ...item };
  } else {
    editingMenuItem.value = { 
      name: '', 
      category_id: '', 
      price: 0, 
      unit: 'phần', 
      is_available: true, 
      branch_id: branchId.value,
      i18n_name: { vi: '', en: '', ja: '' },
      i18n_description: { vi: '', en: '', ja: '' },
      modifiers: [],
      tags: [],
      nutrition: {},
      metadata: {}
    };
  }
  showMenuItemModal.value = true;
};

const saveMenuItem = async () => {
  saving.value = true;
  try {
    if (editingMenuItem.value.id) {
      const { error } = await supabase.from('menu_items')
        .update({
          name: editingMenuItem.value.name,
          category_id: editingMenuItem.value.category_id,
          price: editingMenuItem.value.price,
          unit: editingMenuItem.value.unit,
          is_available: editingMenuItem.value.is_available
        })
        .eq('id', editingMenuItem.value.id);
      if (error) throw error;
    } else {
      const { error } = await supabase.from('menu_items').insert([{
        ...editingMenuItem.value,
        branch_id: branchId.value
      }]);
      if (error) throw error;
    }
    showMenuItemModal.value = false;
    await fetchMenus();
  } catch (e) {
    console.error('Error saving menu item:', e);
  } finally {
    saving.value = false;
  }
};

const togglePackageActive = async (pkg: Package) => {
  const newVal = !pkg.is_active;
  pkg.is_active = newVal; // optimistic update
  try {
    const { error } = await supabase.from('packages').update({ is_active: newVal }).eq('id', pkg.id);
    if (error) throw error;
  } catch (e) {
    console.error(e);
    pkg.is_active = !newVal; // revert
  }
};

const toggleMenuItemAvailable = async (item: MenuItem) => {
  const newVal = !item.is_available;
  item.is_available = newVal; // optimistic update
  try {
    const { error } = await supabase.from('menu_items').update({ is_available: newVal }).eq('id', item.id);
    if (error) throw error;
  } catch (e) {
    console.error(e);
    item.is_available = !newVal; // revert
  }
};
</script>

