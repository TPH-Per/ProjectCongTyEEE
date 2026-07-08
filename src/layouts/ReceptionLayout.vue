<template>
  <div class="flex h-screen overflow-hidden bg-gray-50">
    <!-- Sidebar -->
    <Transition name="sidebar-slide">
      <aside v-if="!isFullscreen" class="w-64 border-r bg-white flex flex-col shrink-0 shadow-sm overflow-hidden">
      <div class="p-5 border-b">
        <div class="flex items-center gap-3">
          <TextLogo size="md" />
        </div>
      </div>
      <nav class="flex-1 px-4 space-y-2 py-6 overflow-y-auto">
        <div
          class="text-[11px] font-extrabold text-gray-500 uppercase tracking-wider mb-2"
        >{{ t('sidebar.activity') }}</div>
        
        <RouterLink
          to="/reception/dashboard"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100"
          active-class="bg-red-50 text-red-600 hover:bg-red-50"
        >
          <LayoutDashboard class="w-[18px] h-[18px]" />
          {{ t('sidebar.dashboard') }}
        </RouterLink>

        <!-- Nhóm Bán hàng -->
        <div class="text-[11px] font-extrabold text-gray-500 uppercase tracking-wider mb-2 mt-4">
          {{ t('sidebar.sales') }}
        </div>
        <RouterLink
          to="/reception/order"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100"
          active-class="bg-red-50 text-red-600 hover:bg-red-50"
        >
          <Utensils class="w-[18px] h-[18px]" />
          {{ t('sidebar.order_menu') }}
        </RouterLink>
        <RouterLink
          to="/reception/floors"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100"
          active-class="bg-red-50 text-red-600 hover:bg-red-50"
        >
          <Grid class="w-[18px] h-[18px]" />
          {{ t('sidebar.floor_plan') }}
        </RouterLink>
        <RouterLink
          to="/reception/order"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100"
          active-class="bg-red-50 text-red-600 hover:bg-red-50"
        >
          <Store class="w-[18px] h-[18px]" />
          {{ t('sidebar.restaurant') }}
        </RouterLink>

        <!-- Nhóm Nghiệp vụ khác -->
        <div class="text-[11px] font-extrabold text-gray-500 uppercase tracking-wider mb-2 mt-4">
          {{ t('sidebar.other_services') }}
        </div>
        <button
          @click="handleQuickAction('Thu khác', '/transactions/income')"
          class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100 text-left"
        >
          <BadgePlus class="w-[18px] h-[18px]" />
          {{ t('sidebar.other_income') }}
        </button>
        <button
          @click="handleQuickAction('Chi khác', '/reception/other-expense')"
          class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100 text-left"
        >
          <BadgeMinus class="w-[18px] h-[18px]" />
          {{ t('sidebar.other_expense') }}
        </button>
        <button
          @click="handleQuickAction('Cấu hình', '/settings')"
          class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100 text-left"
        >
          <SettingsIcon class="w-[18px] h-[18px]" />
          {{ t('sidebar.configuration') }}
        </button>

        <!-- Nhóm Quản trị -->
        <div class="text-[11px] font-extrabold text-gray-500 uppercase tracking-wider mb-2 mt-4">
          {{ t('sidebar.management') }}
        </div>
        <RouterLink
          to="/reception/reports"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100"
          active-class="bg-orange-50 text-[#E8772E] hover:bg-orange-50"
        >
          <Receipt class="w-[18px] h-[18px]" />
          {{ t('sidebar.receipts') }}
        </RouterLink>
        <RouterLink
          to="/reception/revenue-overview"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100"
          active-class="bg-orange-50 text-[#E8772E] hover:bg-orange-50"
        >
          <BarChart3 class="w-[18px] h-[18px]" />
          {{ t('sidebar.reports') }}
        </RouterLink>

        <!-- Ca làm việc -->
        <div class="text-[11px] font-extrabold text-gray-500 uppercase tracking-wider mb-2 mt-4">
          {{ t('sidebar.shift') }}
        </div>
        <RouterLink
          to="/reception/close-shift"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100"
          active-class="bg-red-50 text-red-600 hover:bg-red-50"
        >
          <Clock class="w-[18px] h-[18px]" />
          {{ t('sidebar.close_shift') }}
        </RouterLink>
        <button
          @click="handleQuickAction('Ra ca', '/shift/end')"
          class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100 text-left"
        >
          <LogOut class="w-[18px] h-[18px]" />
          {{ t('sidebar.exit_shift') }}
        </button>
      </nav>
      <div class="p-4 border-t relative">
        <!-- Backdrop to close dropdown on click outside -->
        <div
          v-if="isDropdownOpen"
          class="fixed inset-0 z-40"
          @click="isDropdownOpen = false"
        ></div>

        <!-- Dropdown Menu -->
        <div
          v-if="isDropdownOpen"
          class="absolute bottom-full left-4 right-4 mb-2 bg-white border rounded-xl shadow-lg py-1.5 z-50"
        >
          <button
            @click="handleSignOut"
            class="w-full flex items-center gap-3 px-4 py-2.5 text-sm font-semibold text-red-600 hover:bg-red-50 transition-colors"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
              <polyline points="16 17 21 12 16 7" />
              <line x1="21" x2="9" y1="12" y2="12" />
            </svg>
            <span>{{ $t('layout.logout', 'Đăng xuất') }}</span>
          </button>
        </div>

        <!-- User Profile Card -->
        <div
          @click="isDropdownOpen = !isDropdownOpen"
          class="flex items-center gap-3 px-3 py-2 rounded-xl bg-gray-100 cursor-pointer select-none"
        >
          <img
            :src="stickerUrl"
            alt="Avatar"
            class="w-8 h-8 object-contain drop-shadow-sm rounded-full"
          />
          <div class="flex-1 min-w-0">
            <div class="text-xs font-bold text-gray-900 truncate">
              {{ profile?.full_name || $t('layout.cashier', 'Thu ngân') }}
            </div>
            <div class="text-[10px] text-gray-500 font-semibold">
              {{ roleLabel }}
            </div>
          </div>
        </div>
      </div>
    </aside>
    </Transition>
    <main class="flex-1 flex flex-col overflow-hidden">
      <header
        v-if="!isFullscreen"
        class="h-16 border-b bg-white flex items-center justify-between px-6 shrink-0 shadow-sm z-10"
      >
        <div
          class="font-bold text-xl text-gray-800"
          id="reception-header-title"
        >{{ headerTitle }}</div>
        <div class="flex items-center gap-3">
          <span
            v-if="branchLabel"
            class="text-sm font-semibold text-gray-500 hidden sm:inline"
          >{{ branchLabel }}</span>
          <!-- Single LanguageSwitcher + avatar pair -->
          <div class="flex items-center gap-2 ml-4 border-l pl-4 border-gray-200">
            <LanguageSwitcher />
            <img
              :src="stickerUrl"
              alt="User Avatar"
              class="w-8 h-8 rounded-full border border-gray-200 object-contain bg-gray-100"
            />
          </div>
        </div>
      </header>
      <section :class="['flex-1 overflow-auto bg-gray-50 transition-all duration-300', isFullscreen ? 'p-0' : 'p-6']">
        <RouterView />
      </section>
    </main>
    <!-- Custom Modal other-income -->
    <Transition name="fade">
      <div v-if="showOtherIncomeModal" class="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center z-[9999] p-4">
        <div class="other-income-modal w-full max-w-[600px] bg-white rounded-2xl overflow-hidden shadow-2xl border border-gray-100 text-[#333333]">
          <!-- Header -->
          <div class="modal-header bg-[#1a5276] text-white p-4 flex items-center justify-between">
            <h2 class="text-base font-black uppercase tracking-wide">Thu khác</h2>
            <button @click="showOtherIncomeModal = false" class="text-white/80 hover:text-white transition-colors" type="button">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="18" y1="6" x2="6" y2="18"></line>
                <line x1="6" y1="6" x2="18" y2="18"></line>
              </svg>
            </button>
          </div>

          <!-- Creator Info -->
          <div class="creator-info bg-[#f5f5f5] p-4 border-b border-gray-200">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="flex items-center gap-2">
                <span class="text-xs font-bold text-gray-500 uppercase min-w-[80px]">Người tạo:</span>
                <span class="text-xs font-bold text-gray-800">{{ creator }}</span>
              </div>
              <div class="flex items-center gap-2">
                <span class="text-xs font-bold text-gray-500 uppercase min-w-[80px]">Ngày lập:</span>
                <input v-model="createdDate" type="text" class="bg-white border border-gray-300 rounded px-2.5 py-1 text-xs font-mono font-bold w-full max-w-[160px] focus:outline-none focus:border-[#E8772E]" />
              </div>
            </div>
          </div>

          <!-- Form Content -->
          <form @submit.prevent="handleSave" class="form-content p-5 max-h-[420px] overflow-y-auto space-y-4">
            <!-- Đối tượng -->
            <div class="form-row required flex flex-col gap-1">
              <label class="text-xs font-bold text-gray-600">Đối tượng <span class="text-red-500">*</span></label>
              <div class="input-with-button flex items-center gap-1.5">
                <input 
                  v-model="form.object" 
                  type="text" 
                  class="form-input flex-1 px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none focus:ring-2 focus:ring-[#E8772E]/10" 
                  placeholder="Nhập tên đối tượng..."
                  required
                />
                <button type="button" @click="triggerSelectObject" class="btn-browse px-3 py-2 bg-gray-100 hover:bg-gray-200 border border-gray-300 text-xs font-bold text-gray-700 rounded-lg active:scale-95 transition-all">...</button>
              </div>
            </div>

            <!-- Loại thu & Khoản thu (Grid) -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- Loại thu -->
              <div class="form-row required flex flex-col gap-1">
                <label class="text-xs font-bold text-gray-600">Loại thu <span class="text-red-500">*</span></label>
                <select v-model="form.incomeType" class="form-select w-full px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none" required>
                  <option value="other">Thu Khác</option>
                  <option value="deposit">Tiền đặt cọc</option>
                  <option value="refund">Hoàn tiền</option>
                </select>
              </div>

              <!-- Khoản thu -->
              <div class="form-row required flex flex-col gap-1">
                <label class="text-xs font-bold text-gray-600">Khoản thu <span class="text-red-500">*</span></label>
                <select v-model="form.incomeItem" class="form-select w-full px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none" required>
                  <option value="withdraw">Rút tiền dư</option>
                  <option value="adjustment">Điều chỉnh</option>
                  <option value="other">Khác</option>
                </select>
              </div>
            </div>

            <!-- Tiền thu (Highlight hồng nhạt) -->
            <div class="form-row required highlight bg-[#FFF0F0] border border-red-200/50 p-3.5 rounded-xl flex flex-col gap-1">
              <label class="text-xs font-bold text-red-700">Tiền thu <span class="text-red-500">*</span></label>
              <div class="input-with-button flex items-center gap-1.5">
                <input 
                  :value="formattedAmount"
                  @input="handleAmountInput"
                  type="text" 
                  class="form-input flex-1 px-3 py-2 border border-red-300 rounded-lg text-xs font-mono font-bold text-right text-red-600 focus:outline-none focus:ring-2 focus:ring-red-100" 
                  placeholder="0"
                  required
                />
                <button type="button" class="btn-browse px-3 py-2 bg-red-100 hover:bg-red-200 border border-red-300 text-xs font-bold text-red-700 rounded-lg active:scale-95 transition-all">...</button>
              </div>
            </div>

            <!-- Lý do -->
            <div class="form-row flex flex-col gap-1">
              <label class="text-xs font-bold text-gray-600">Lý do</label>
              <div class="input-with-button flex items-center gap-1.5">
                <input 
                  v-model="form.reason" 
                  type="text" 
                  class="form-input flex-1 px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none" 
                  placeholder="Nhập lý do thu tiền..."
                />
                <button type="button" class="btn-browse px-3 py-2 bg-gray-100 hover:bg-gray-200 border border-gray-300 text-xs font-bold text-gray-700 rounded-lg active:scale-95 transition-all">...</button>
              </div>
            </div>

            <!-- Số chứng từ & Mã đặt chỗ (Grid) -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- Số chứng từ -->
              <div class="form-row flex flex-col gap-1">
                <label class="text-xs font-bold text-gray-600">Số chứng từ</label>
                <input 
                  v-model="form.voucherNumber" 
                  type="text" 
                  class="form-input w-full px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none" 
                  placeholder="Hệ thống tự động phát sinh"
                />
              </div>

              <!-- Mã đặt chỗ -->
              <div class="form-row flex flex-col gap-1">
                <label class="text-xs font-bold text-gray-600">Mã đặt chỗ</label>
                <input 
                  v-model="form.bookingCode" 
                  type="text" 
                  class="form-input w-full px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none" 
                  placeholder="Nhập mã đặt chỗ (nếu có)"
                />
              </div>
            </div>

            <!-- Tiền mặt -->
            <div class="form-row checkbox-row flex items-center gap-2 pt-2 select-none">
              <input 
                v-model="form.isCash" 
                type="checkbox" 
                id="isCash" 
                class="w-4.5 h-4.5 accent-[#E8772E] cursor-pointer"
              />
              <label for="isCash" class="text-xs font-bold text-gray-700 cursor-pointer">Tiền mặt</label>
            </div>
          </form>

          <!-- Footer Actions -->
          <div class="modal-footer p-4 border-t border-gray-200 bg-gray-50 flex items-center justify-end gap-3">
            <button 
              type="button" 
              class="btn btn-save-print px-4 py-2 bg-[#4CAF50] hover:bg-[#43A047] text-white text-xs font-extrabold rounded-lg shadow transition-all active:scale-95 flex items-center gap-1.5"
              @click="handleSaveAndPrint"
            >
              🖨️ Lưu và in
            </button>
            <button 
              type="button" 
              class="btn btn-save px-4 py-2 bg-[#FF9800] hover:bg-[#F57C00] text-white text-xs font-extrabold rounded-lg shadow transition-all active:scale-95"
              @click="handleSave"
            >
              💾 Lưu
            </button>
            <button 
              type="button" 
              class="btn btn-cancel px-4 py-2 bg-[#F44336] hover:bg-[#E53935] text-white text-xs font-extrabold rounded-lg shadow transition-all active:scale-95"
              @click="showOtherIncomeModal = false"
            >
              ✕ Bỏ qua
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Custom Modal settings -->
    <Transition name="fade">
      <div v-if="showSettingsModal" class="fixed inset-0 bg-black/60 backdrop-blur-xs flex items-center justify-center z-[9999] p-4">
        <div class="settings-modal w-full max-w-[500px] bg-white rounded-2xl overflow-hidden shadow-2xl border border-gray-100 text-[#333333]">
          <!-- Header -->
          <div class="modal-header bg-[#1a5276] text-white p-4 flex items-center justify-between">
            <h2 class="text-base font-black uppercase tracking-wide">Cấu hình</h2>
            <button @click="showSettingsModal = false" class="text-white/80 hover:text-white transition-colors" type="button">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="18" y1="6" x2="6" y2="18"></line>
                <line x1="6" y1="6" x2="18" y2="18"></line>
              </svg>
            </button>
          </div>

          <!-- Form Content -->
          <div class="modal-content p-5 space-y-4">
            <!-- Username -->
            <div class="form-row flex flex-col gap-1">
              <label class="text-xs font-bold text-gray-600">Tên đăng nhập</label>
              <div class="input-group flex items-center gap-1.5">
                <input 
                  v-model="settingsUsername" 
                  type="text" 
                  class="form-input flex-1 px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none"
                  placeholder="Nhập tên đăng nhập"
                />
                <button type="button" class="btn-browse px-3 py-2 bg-gray-100 hover:bg-gray-200 border border-gray-300 text-xs font-bold text-gray-700 rounded-lg active:scale-95 transition-all">...</button>
              </div>
            </div>

            <!-- Password -->
            <div class="form-row flex flex-col gap-1">
              <label class="text-xs font-bold text-gray-600">Mật khẩu</label>
              <div class="input-group flex items-center gap-1.5">
                <input 
                  v-model="settingsPassword" 
                  type="password" 
                  class="form-input flex-1 px-3 py-2 border border-gray-300 rounded-lg text-xs focus:outline-none"
                  placeholder="Nhập mật khẩu"
                />
                <button type="button" class="btn-browse px-3 py-2 bg-gray-100 hover:bg-gray-200 border border-gray-300 text-xs font-bold text-gray-700 rounded-lg active:scale-95 transition-all">...</button>
              </div>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="modal-footer p-4 border-t border-gray-200 bg-gray-50 flex items-center justify-end gap-3">
            <button 
              type="button" 
              class="btn btn-confirm px-6 py-2 bg-[#4DB6AC] hover:bg-[#40a095] text-white text-xs font-extrabold rounded-lg shadow transition-all active:scale-95" 
              @click="handleSaveSettings"
            >
              Xác nhận
            </button>
            <button 
              type="button" 
              class="btn btn-skip px-6 py-2 bg-[#E57373] hover:bg-[#d9534f] text-white text-xs font-extrabold rounded-lg shadow transition-all active:scale-95" 
              @click="showSettingsModal = false"
            >
              Bỏ qua
            </button>
          </div>
        </div>
      </div>
    </Transition>

  </div>
</template>

<script setup lang="ts">
import LanguageSwitcher from '@/components/LanguageSwitcher.vue'
import { useI18n } from 'vue-i18n'
import { ref, computed } from 'vue'
import { RouterView, RouterLink, useRouter, useRoute } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useUserSticker } from '@/composables/useUserSticker'
import TextLogo from '@/components/TextLogo.vue'
import Swal from 'sweetalert2'
import { 
  Utensils, 
  BadgePlus, 
  BadgeMinus, 
  Settings as SettingsIcon, 
  Receipt, 
  BarChart3,
  LogOut,
  LayoutDashboard,
  Grid,
  Clock,
  Store
} from 'lucide-vue-next'

const router = useRouter()
const route = useRoute()
const { t } = useI18n()
const { signOut, profile, role } = useAuth()
const { stickerUrl } = useUserSticker()
const isDropdownOpen = ref(false)

const showOtherIncomeModal = ref(false)
const showSettingsModal = ref(false)
const settingsUsername = ref('mo')
const settingsPassword = ref('')

const handleSaveSettings = () => {
  Swal.fire({
    title: 'Thành công',
    text: `Đã cập nhật cấu hình cho tài khoản ${settingsUsername.value}!`,
    icon: 'success',
    confirmButtonText: 'Đóng',
    confirmButtonColor: '#4DB6AC'
  })
  showSettingsModal.value = false
}
const creator = ref('Dương Thị Mộng')
const createdDate = ref('02/07/2026 15:08:41')

const form = ref({
  object: '',
  incomeType: 'other',
  incomeItem: 'withdraw',
  amount: 0,
  reason: '',
  voucherNumber: '',
  bookingCode: '',
  isCash: true,
})

const formattedAmount = computed(() => {
  if (!form.value.amount) return ''
  return Number(form.value.amount).toLocaleString('vi-VN')
})

const handleAmountInput = (e: Event) => {
  const target = e.target as HTMLInputElement
  const rawValue = target.value.replace(/[^0-9]/g, '')
  form.value.amount = rawValue ? parseInt(rawValue, 10) : 0
}

const triggerSelectObject = () => {
  form.value.object = 'Khách vãng lai'
  triggerToast('info', 'Đã tự động chọn Đối tượng: Khách vãng lai')
}

const triggerToast = (type: 'success' | 'error' | 'info' | 'warning', text: string) => {
  Swal.fire({
    toast: true,
    position: 'top-end',
    showConfirmButton: false,
    timer: 3000,
    timerProgressBar: true,
    icon: type,
    title: text
  })
}

const handleSaveAndPrint = () => {
  if (!form.value.object) {
    triggerToast('error', 'Vui lòng nhập Đối tượng!')
    return
  }
  if (!form.value.amount) {
    triggerToast('error', 'Vui lòng nhập Số tiền thu!')
    return
  }
  Swal.fire({
    title: 'Thành công',
    text: `Đã lưu và in phiếu thu cho ${form.value.object} với số tiền ${Number(form.value.amount).toLocaleString('vi-VN')}đ!`,
    icon: 'success',
    confirmButtonText: 'Đóng',
    confirmButtonColor: '#4CAF50'
  })
  showOtherIncomeModal.value = false
}

const handleSave = () => {
  if (!form.value.object) {
    triggerToast('error', 'Vui lòng nhập Đối tượng!')
    return
  }
  if (!form.value.amount) {
    triggerToast('error', 'Vui lòng nhập Số tiền thu!')
    return
  }
  Swal.fire({
    title: 'Thành công',
    text: `Đã lưu thành công phiếu thu của ${form.value.object}!`,
    icon: 'success',
    confirmButtonText: 'Đóng',
    confirmButtonColor: '#FF9800'
  })
  showOtherIncomeModal.value = false
}

function handleQuickAction(name: string, path: string) {
  if (name === 'Ra ca') {
    Swal.fire({
      title: 'Xác nhận ra ca?',
      text: 'Bạn có chắc chắn muốn kết thúc ca làm việc hiện tại không?',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Đồng ý',
      cancelButtonText: 'Hủy',
      confirmButtonColor: '#8E24AA',
      cancelButtonColor: '#aaa'
    }).then((result) => {
      if (result.isConfirmed) {
        router.push('/reception/close-shift')
      }
    })
    return
  }

  // Check auth roles for admin voucher
  if (path.startsWith('/admin') && role.value !== 'superadmin') {
    Swal.fire({
      title: 'Không có quyền truy cập',
      text: 'Chức năng này thuộc phân hệ Quản trị (chỉ dành cho Admin/Superadmin).',
      icon: 'error',
      confirmButtonText: 'Đóng',
      confirmButtonColor: '#E8772E'
    })
    return
  }

  // Other income popup modal trigger
  if (name === 'Thu khác') {
    showOtherIncomeModal.value = true
    return
  }

  // Settings popup modal trigger
  if (path === '/settings') {
    showSettingsModal.value = true
    return
  }

  // Placeholder paths
  if (path === '/admin/reports' || path === '/restaurant-pos') {
    Swal.fire({
      title: 'Chức năng đang phát triển',
      text: `Phân hệ ${name} đang được phát triển. Vui lòng thử lại sau.`,
      icon: 'info',
      confirmButtonText: 'Đóng',
      confirmButtonColor: '#E8772E'
    })
    return
  }

  router.push(path)
}

const isFullscreen = computed(() => route.meta.fullscreen === true);

const headerTitle = computed(() => {
  if (route.path.includes('/reception/close-shift')) return t('reception.title.close_shift')
  if (route.path.includes('/reception/floors')) return t('reception.title.floors')
  if (route.path.includes('/reception/order')) return t('reception.title.order')
  if (route.path.includes('/reception/checkout')) return t('reception.title.checkout')
  return t('reception.title.dashboard')
})

const ROLE_LABELS: Record<string, string> = {
  superadmin: 'Quản trị viên (Superadmin)',
  manager: 'Quản lý',
  reception: 'Thu ngân / Lễ tân',
  staff: 'Nhân viên',
  procurement_manager: 'Quản lý Mua hàng',
  procurement_staff: 'Nhân viên Mua hàng',
  accountant: 'Kế toán',
  customer: 'Khách hàng',
  crm_manager: 'Quản lý CRM',
  marketing: 'Marketing'
};
const roleLabel = computed(() => {
  const r = role.value ?? profile.value?.role
  if (!r) return '—'
  const key = `role.${r}`
  const fallback = ROLE_LABELS[r] ?? r
  const translated = t(key)
  return translated !== key ? translated : fallback
})

const branchLabel = computed(() => {
  const bid = profile.value?.branch_id
  if (!bid) return ''
  return t('layout.branch_id', { id: bid.slice(0, 8) })
})

async function handleSignOut() {
  await signOut()
  await router.push({ name: 'login' })
}
</script>

<style scoped>
.sidebar-slide-enter-active,
.sidebar-slide-leave-active {
  transition: all 0.3s ease;
}

.sidebar-slide-enter-from,
.sidebar-slide-leave-to {
  width: 0 !important;
  opacity: 0;
  border-right-width: 0 !important;
  padding-left: 0 !important;
  padding-right: 0 !important;
}

/* ===== OTHER INCOME MODAL ===== */
.other-income-modal {
  width: 100%;
  max-width: 600px;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
}

.creator-info {
  background: #f5f5f5;
  padding: 12px 16px;
  border-bottom: 1px solid #ddd;
}

.form-input, .form-select {
  flex: 1;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 13px;
  background: white;
}

.form-input:focus, .form-select:focus {
  outline: none;
  border-color: #E8772E;
  box-shadow: 0 0 0 2px rgba(232, 119, 46, 0.1);
}

.btn-browse {
  padding: 8px 12px;
  background: #f5f5f5;
  border: 1px solid #ddd;
  border-radius: 4px;
  cursor: pointer;
  font-size: 13px;
  color: #666;
}

.btn-browse:hover {
  background: #e0e0e0;
}

.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-save-print {
  background: #4CAF50;
  color: white;
}

.btn-save-print:hover {
  background: #43A047;
}

.btn-save {
  background: #FF9800;
  color: white;
}

.btn-save:hover {
  background: #F57C00;
}

.btn-cancel {
  background: #F44336;
  color: white;
}

.btn-cancel:hover {
  background: #E53935;
}

/* ===== SETTINGS MODAL ===== */
.settings-modal {
  width: 100%;
  max-width: 500px;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
}

.btn-confirm {
  background: #4DB6AC;
  color: white;
}

.btn-confirm:hover {
  background: #40a095;
}

.btn-skip {
  background: #E57373;
  color: white;
}

.btn-skip:hover {
  background: #d9534f;
}
</style>

