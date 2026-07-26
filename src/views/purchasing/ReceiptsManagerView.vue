<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { getGoodsReceipts, type GoodsReceipt } from '@/api/procurement.api'
import { useAuth } from '@/composables/useAuth'
import { usePurchasing } from '@/composables/usePurchasing'
import { useI18nStore, LANGUAGE_META } from '@/stores/i18n'

const { role, isAdmin, branchId } = useAuth()
const isProcurementManager = computed(() => role.value === 'procurement_manager' || isAdmin.value)
const i18nStore = useI18nStore()
const { t } = i18nStore

const {
  fetchSuppliers,
  fetchIngredients,
  submitGoodsReceipt,
  suppliers,
  ingredients,
  loading: submitting
} = usePurchasing()

const receipts = ref<GoodsReceipt[]>([])
const loading = ref(true)
const errorMsg = ref('')

const showCreateModal = ref(false)
const newReceipt = ref({
  supplier_id: '',
  receipt_code: `GR-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${Math.floor(Math.random() * 1000)}`,
  scan_image_url: '',
  items: [] as Array<{ ingredient_name: string; unit: string; quantity: number; unit_price: number }>
})

const loadData = async () => {
  try {
    loading.value = true
    receipts.value = await getGoodsReceipts()
    await fetchSuppliers()
    await fetchIngredients()
  } catch (e: any) {
    errorMsg.value = e.message || t('purchasing.receipts.alert.loadError')
  } finally {
    loading.value = false
  }
}

const addRow = () => {
  newReceipt.value.items.push({
    ingredient_name: '',
    unit: 'unit',
    quantity: 1,
    unit_price: 0
  })
}

const removeRow = (index: number) => {
  newReceipt.value.items.splice(index, 1)
}

const handleCreateReceipt = async () => {
  if (!newReceipt.value.supplier_id) {
    alert(t('purchasing.receipts.alert.selectSupplier'))
    return
  }
  if (newReceipt.value.items.length === 0) {
    alert(t('purchasing.receipts.alert.addItem'))
    return
  }
  
  for (const item of newReceipt.value.items) {
    if (!item.ingredient_name.trim()) {
      alert(t('purchasing.receipts.alert.ingredientNameEmpty'))
      return
    }
    if (item.quantity <= 0 || item.unit_price < 0) {
      alert(t('purchasing.receipts.alert.invalidQtyPrice'))
      return
    }
  }

  try {
    await submitGoodsReceipt(
      branchId.value || '00000000-0000-0000-0000-000000000000',
      newReceipt.value.receipt_code,
      newReceipt.value.supplier_id,
      newReceipt.value.scan_image_url,
      newReceipt.value.items
    )
    showCreateModal.value = false
    await loadData()
    // Reset form
    newReceipt.value = {
      supplier_id: '',
      receipt_code: `GR-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${Math.floor(Math.random() * 1000)}`,
      scan_image_url: '',
      items: []
    }
  } catch (err: any) {
    alert(err.message || t('purchasing.receipts.alert.createError'))
  }
}

onMounted(() => {
  loadData()
})
</script>

<template>
  <div class="p-6">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">{{ t('purchasing.receipts.title') }}</h1>
      <div class="flex items-center gap-4">
        <select 
          :value="i18nStore.locale" 
          @change="i18nStore.setLocale(($event.target as HTMLSelectElement).value as any)"
          class="border rounded-lg px-3 py-2 text-sm bg-white focus:ring-2 focus:ring-blue-500 outline-none shadow-sm cursor-pointer"
        >
          <option v-for="lang in i18nStore.availableLocales" :key="lang" :value="lang">
            {{ LANGUAGE_META[lang].flag }} {{ LANGUAGE_META[lang].nativeLabel }}
          </option>
        </select>
        <button 
          @click="showCreateModal = true"
          class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium shadow-sm"
        >
          {{ t('purchasing.receipts.createButton') }}
        </button>
      </div>
    </div>

    <div v-if="errorMsg" class="mb-4 p-4 bg-red-50 text-red-700 rounded-md">
      {{ errorMsg }}
    </div>

    <div v-if="loading" class="text-gray-500">{{ t('purchasing.receipts.loading') }}</div>

    <div v-else class="grid gap-6">
      <div 
        v-for="receipt in receipts" 
        :key="receipt.id"
        class="p-4 bg-white border rounded-lg shadow-sm"
      >
        <div class="flex justify-between mb-4 border-b pb-2">
          <div>
            <div class="font-semibold text-lg">{{ receipt.receipt_code }} <span class="text-sm font-normal text-gray-500 ml-2">({{ receipt.branch_name || t('purchasing.receipts.defaultBranch') }})</span></div>
            <div class="text-sm text-gray-500">{{ new Date(receipt.created_at).toLocaleString() }}</div>
            <div v-if="receipt.supplier_name" class="text-sm text-blue-600 mt-1">{{ t('purchasing.receipts.supplier') }} {{ receipt.supplier_name }}</div>
          </div>
          <div class="text-right">
            <span 
              class="px-3 py-1 rounded-full text-xs font-medium"
              :class="{
                'bg-yellow-100 text-yellow-800': receipt.status === 'PENDING',
                'bg-green-100 text-green-800': receipt.status === 'COMPLETED',
                'bg-red-100 text-red-800': receipt.status === 'CANCELLED'
              }"
            >
              {{ receipt.status }}
            </span>
            <div class="mt-2 font-bold text-gray-800">
              {{ t('purchasing.receipts.total') }} {{ receipt.total_amount?.toLocaleString() }} ₫
            </div>
          </div>
        </div>

        <div v-if="receipt.items_jsonb && receipt.items_jsonb.length > 0" class="mb-4 bg-gray-50 p-3 rounded">
          <h4 class="font-medium mb-2 text-sm text-gray-700">{{ t('purchasing.receipts.itemDetails') }}</h4>
          <table class="w-full text-sm">
            <thead>
              <tr class="text-left text-gray-500 border-b">
                <th class="pb-1">{{ t('purchasing.receipts.item') }}</th>
                <th class="pb-1 text-right">{{ t('purchasing.receipts.qty') }}</th>
                <th class="pb-1 text-right">{{ t('purchasing.receipts.unitPrice') }}</th>
                <th class="pb-1 text-right">{{ t('purchasing.receipts.totalPrice') }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, idx) in receipt.items_jsonb" :key="idx" class="border-b last:border-0">
                <td class="py-1">{{ item.ingredient_name }}</td>
                <td class="py-1 text-right">{{ item.quantity }} {{ item.unit }}</td>
                <td class="py-1 text-right">{{ item.unit_price?.toLocaleString() }} ₫</td>
                <td class="py-1 text-right">{{ item.total_price?.toLocaleString() }} ₫</td>
              </tr>
            </tbody>
          </table>
        </div>
        
        <div v-if="receipt.notes" class="text-sm text-gray-600 italic">
          {{ t('purchasing.receipts.notes') }} {{ receipt.notes }}
        </div>
      </div>
      
      <div v-if="receipts.length === 0" class="text-center p-8 bg-gray-50 rounded-lg text-gray-500">
        {{ t('purchasing.receipts.empty') }}
      </div>
    </div>

    <!-- Modal Tạo Phiếu Nhập -->
    <div v-if="showCreateModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div class="bg-white rounded-xl shadow-xl w-full max-w-4xl max-h-[90vh] overflow-y-auto">
        <div class="p-6 border-b sticky top-0 bg-white z-10 flex justify-between items-center">
          <h2 class="text-xl font-bold">{{ t('purchasing.receipts.createModalTitle') }}</h2>
          <button @click="showCreateModal = false" class="text-gray-500 hover:text-gray-700">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>
        </div>
        
        <div class="p-6 space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('purchasing.receipts.receiptCode') }}</label>
              <input v-model="newReceipt.receipt_code" type="text" class="w-full border rounded-lg p-2 bg-gray-50" readonly />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">{{ t('purchasing.receipts.supplierLabel') }} <span class="text-red-500">*</span></label>
              <select v-model="newReceipt.supplier_id" class="w-full border rounded-lg p-2 focus:ring-2 focus:ring-blue-500 outline-none">
                <option value="">{{ t('purchasing.receipts.selectSupplier') }}</option>
                <option v-for="sup in suppliers" :key="sup.id" :value="sup.id">{{ sup.name }}</option>
              </select>
            </div>
          </div>

          <div>
            <div class="flex justify-between items-center mb-2">
              <h3 class="font-medium">{{ t('purchasing.receipts.itemList') }}</h3>
              <button @click="addRow" class="text-sm text-blue-600 hover:text-blue-800 font-medium">
                {{ t('purchasing.receipts.addRow') }}
              </button>
            </div>
            
            <!-- Datalist for ingredient suggestions -->
            <datalist id="ingredient-suggestions">
              <option v-for="ing in ingredients" :key="ing.id" :value="ing.name"></option>
            </datalist>

            <div class="border rounded-lg overflow-hidden">
              <table class="w-full text-sm text-left">
                <thead class="bg-gray-50 text-gray-700">
                  <tr>
                    <th class="p-3">{{ t('purchasing.receipts.ingredientName') }}</th>
                    <th class="p-3 w-24">{{ t('purchasing.receipts.unit') }}</th>
                    <th class="p-3 w-32">{{ t('purchasing.receipts.qty') }}</th>
                    <th class="p-3 w-40">{{ t('purchasing.receipts.unitPrice') }}</th>
                    <th class="p-3 w-40">{{ t('purchasing.receipts.totalPrice') }}</th>
                    <th class="p-3 w-16 text-center">{{ t('purchasing.receipts.delete') }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(item, idx) in newReceipt.items" :key="idx" class="border-t">
                    <td class="p-2">
                      <input 
                        v-model="item.ingredient_name" 
                        type="text" 
                        list="ingredient-suggestions"
                        class="w-full border rounded p-2" 
                        :placeholder="t('purchasing.receipts.selectOrEnterName')"
                      />
                    </td>
                    <td class="p-2">
                      <input v-model="item.unit" type="text" class="w-full border rounded p-2" :placeholder="t('purchasing.receipts.exampleUnit')" />
                    </td>
                    <td class="p-2">
                      <input v-model.number="item.quantity" type="number" min="0.01" step="0.01" class="w-full border rounded p-2" />
                    </td>
                    <td class="p-2">
                      <input v-model.number="item.unit_price" type="number" min="0" class="w-full border rounded p-2" />
                    </td>
                    <td class="p-2 font-medium text-gray-700 align-middle">
                      {{ (item.quantity * item.unit_price).toLocaleString() }} ₫
                    </td>
                    <td class="p-2 text-center align-middle">
                      <button @click="removeRow(idx)" class="text-red-500 hover:text-red-700">
                        <svg class="w-5 h-5 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                      </button>
                    </td>
                  </tr>
                  <tr v-if="newReceipt.items.length === 0">
                    <td colspan="6" class="p-4 text-center text-gray-500 italic">{{ t('purchasing.receipts.noItemsAdded') }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
            
            <div class="mt-4 flex justify-end">
              <div class="text-lg font-bold">
                {{ t('purchasing.receipts.totalAmount') }} {{ newReceipt.items.reduce((sum, item) => sum + (item.quantity * item.unit_price), 0).toLocaleString() }} ₫
              </div>
            </div>
          </div>
        </div>

        <div class="p-6 border-t bg-gray-50 sticky bottom-0 flex justify-end gap-3 rounded-b-xl">
          <button 
            @click="showCreateModal = false"
            class="px-4 py-2 border rounded-lg hover:bg-gray-100 font-medium text-gray-700"
          >
            {{ t('purchasing.receipts.cancel') }}
          </button>
          <button
            @click="handleCreateReceipt"
            :disabled="submitting"
            class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium shadow-sm disabled:opacity-50 flex items-center gap-2"
          >
            <svg v-if="submitting" class="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
            {{ submitting ? t('purchasing.receipts.saving') : t('purchasing.receipts.saveReceipt') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
