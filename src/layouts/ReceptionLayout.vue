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
        >{{ $t('layout.activity', 'Hoạt động') }}</div>
        
        <RouterLink
          to="/reception/dashboard"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100"
          active-class="bg-red-50 text-red-600 hover:bg-red-50"
        >
          <LayoutDashboard class="w-[18px] h-[18px]" />
          {{ $t('layout.dashboard', 'Bảng điều khiển') }}
        </RouterLink>

        <!-- Nhóm Bán hàng -->
        <div class="text-[11px] font-extrabold text-gray-500 uppercase tracking-wider mb-2 mt-4">
          Bán hàng
        </div>
        <RouterLink
          to="/reception/order"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100"
          active-class="bg-red-50 text-red-600 hover:bg-red-50"
        >
          <Utensils class="w-[18px] h-[18px]" />
          Chọn món
        </RouterLink>
        <RouterLink
          to="/reception/floors"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100"
          active-class="bg-red-50 text-red-600 hover:bg-red-50"
        >
          <Grid class="w-[18px] h-[18px]" />
          Sơ đồ bàn
        </RouterLink>
        <RouterLink
          to="/reception/order"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100"
          active-class="bg-red-50 text-red-600 hover:bg-red-50"
        >
          <Store class="w-[18px] h-[18px]" />
          Nhà hàng
        </RouterLink>

        <!-- Nhóm Nghiệp vụ khác -->
        <div class="text-[11px] font-extrabold text-gray-500 uppercase tracking-wider mb-2 mt-4">
          Nghiệp vụ khác
        </div>
        <button
          @click="handleQuickAction('Thu khác', '/transactions/income')"
          class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100 text-left"
        >
          <BadgePlus class="w-[18px] h-[18px]" />
          Thu khác
        </button>
        <button
          @click="handleQuickAction('Chi khác', '/transactions/expense')"
          class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100 text-left"
        >
          <BadgeMinus class="w-[18px] h-[18px]" />
          Chi khác
        </button>
        <button
          @click="handleQuickAction('Cấu hình', '/settings')"
          class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100 text-left"
        >
          <SettingsIcon class="w-[18px] h-[18px]" />
          Cấu hình
        </button>

        <!-- Nhóm Quản trị -->
        <div class="text-[11px] font-extrabold text-gray-500 uppercase tracking-wider mb-2 mt-4">
          Quản trị
        </div>
        <button
          @click="handleQuickAction('Phiếu', '/admin/vouchers')"
          class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100 text-left"
        >
          <Receipt class="w-[18px] h-[18px]" />
          Phiếu
        </button>
        <button
          @click="handleQuickAction('Báo cáo', '/admin/reports')"
          class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100 text-left"
        >
          <BarChart3 class="w-[18px] h-[18px]" />
          Báo cáo
        </button>

        <!-- Ca làm việc -->
        <div class="text-[11px] font-extrabold text-gray-500 uppercase tracking-wider mb-2 mt-4">
          Ca làm việc
        </div>
        <RouterLink
          to="/reception/close-shift"
          class="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100"
          active-class="bg-red-50 text-red-600 hover:bg-red-50"
        >
          <Clock class="w-[18px] h-[18px]" />
          Tổng Kết Ca
        </RouterLink>
        <button
          @click="handleQuickAction('Ra ca', '/shift/end')"
          class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all text-sm font-semibold text-gray-600 hover:bg-gray-100 text-left"
        >
          <LogOut class="w-[18px] h-[18px]" />
          Ra ca
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

  // Placeholder paths
  if (path === '/transactions/income' || path === '/transactions/expense' || path === '/settings' || path === '/admin/reports' || path === '/restaurant-pos') {
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
  if (route.path.includes('/reception/close-shift')) return 'Tổng Kết Ca'
  if (route.path.includes('/reception/floors')) return 'Sơ đồ bàn & Đặt chỗ'
  if (route.path.includes('/reception/order')) return 'Chọn món & Gọi đồ'
  if (route.path.includes('/reception/checkout')) return 'Thanh toán hóa đơn'
  return 'Bảng điều khiển'
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
  return ROLE_LABELS[r] ?? r
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
</style>

