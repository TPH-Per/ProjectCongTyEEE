<template>
  <div class="flex h-screen overflow-hidden bg-slate-50">
    <!-- Sidebar -->
    <aside class="w-60 border-r border-slate-200 bg-white shadow-sm flex flex-col shrink-0">
      <div class="p-5 border-b border-slate-100">
        <div class="flex items-center gap-2">
          <div class="w-9 h-9 rounded-xl bg-gradient-to-br from-blue-600 to-indigo-600 flex items-center justify-center text-white font-black text-sm shadow-md shadow-blue-500/20">
            NC
          </div>
          <div>
            <h1 class="text-sm font-black text-slate-900 tracking-tight">NGƯU CÁT</h1>
            <p class="text-[10px] text-slate-400 font-semibold uppercase tracking-wider">Booking Manager</p>
          </div>
        </div>
      </div>

      <nav class="flex-1 px-3 space-y-1 py-4">
        <div class="text-[10px] font-bold text-slate-400 uppercase tracking-wider px-3 mb-1">Vận hành</div>
        <RouterLink 
          to="/" 
          :class="[
            'flex items-center gap-3 px-3 py-2 rounded-lg transition-colors text-sm font-medium',
            route.path === '/' ? 'bg-blue-50 text-blue-600 font-semibold' : 'text-slate-700 hover:bg-slate-100'
          ]"
        >
          <LayoutDashboard :size="16" />
          <span>Lịch đặt bàn</span>
        </RouterLink>
        <RouterLink 
          to="/list" 
          :class="[
            'flex items-center gap-3 px-3 py-2 rounded-lg transition-colors text-sm font-medium',
            route.path === '/list' ? 'bg-blue-50 text-blue-600 font-semibold' : 'text-slate-700 hover:bg-slate-100'
          ]"
        >
          <List :size="16" />
          <span>Danh sách</span>
        </RouterLink>
        <RouterLink 
          to="/floor-plan" 
          :class="[
            'flex items-center gap-3 px-3 py-2 rounded-lg transition-colors text-sm font-medium',
            route.path === '/floor-plan' ? 'bg-blue-50 text-blue-600 font-semibold' : 'text-slate-700 hover:bg-slate-100'
          ]"
        >
          <Map :size="16" />
          <span>Sơ đồ bàn</span>
        </RouterLink>

        <div class="text-[10px] font-bold text-slate-400 uppercase tracking-wider px-3 mb-1 mt-5">Phục vụ</div>
        <RouterLink 
          to="/order/SF_00001729" 
          :class="[
            'flex items-center gap-3 px-3 py-2 rounded-lg transition-colors text-sm font-medium',
            route.path.startsWith('/order') ? 'bg-blue-50 text-blue-600 font-semibold' : 'text-slate-700 hover:bg-slate-100'
          ]"
        >
          <Utensils :size="16" />
          <span>Chọn món</span>
        </RouterLink>

        <div class="text-[10px] font-bold text-slate-400 uppercase tracking-wider px-3 mb-1 mt-5">Hệ thống</div>
        <button class="w-full flex items-center gap-3 px-3 py-2 text-slate-600 rounded-lg hover:bg-slate-100 transition-colors text-sm font-medium text-left">
          <Settings :size="16" />
          <span>Cấu hình</span>
        </button>
      </nav>

      <div class="p-3 border-t border-slate-100 space-y-1">
        <div class="flex items-center gap-2.5 px-3 py-2 rounded-lg bg-slate-50">
          <div class="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-indigo-500 flex items-center justify-center text-white text-xs font-bold">
            NA
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-xs font-bold text-slate-800 truncate">Nguyễn Văn A</div>
            <div class="text-[10px] text-slate-500">Quản lý ca</div>
          </div>
          <button class="p-1 rounded hover:bg-white text-slate-400">
            <LogOut :size="13" />
          </button>
        </div>
      </div>
    </aside>

    <!-- Main Content Area -->
    <main class="flex-1 flex flex-col overflow-hidden">
      <!-- Header -->
      <header class="h-16 border-b border-slate-200 bg-white flex items-center justify-between px-6 shrink-0">
        <div class="flex items-center gap-3">
          <div class="flex items-center gap-2 px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-sm">
            <div class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
            <span class="font-semibold text-slate-700">Chi nhánh: Ngưu Cát Quận 1</span>
            <ChevronDown :size="14" class="text-slate-400" />
          </div>
        </div>

        <div class="flex items-center gap-2">
          <div class="relative">
            <Search :size="14" class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Tìm nhanh..."
              class="pl-9 pr-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-sm w-56 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
            />
          </div>
          <button class="relative p-2 rounded-lg hover:bg-slate-100 text-slate-600">
            <Bell :size="16" />
            <span class="absolute top-1 right-1 w-2 h-2 rounded-full bg-rose-500" />
          </button>
          <div class="w-px h-6 bg-slate-200" />
          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-indigo-500 flex items-center justify-center text-white text-xs font-bold">
              NA
            </div>
            <ChevronDown :size="14" class="text-slate-400" />
          </div>
        </div>
      </header>

      <!-- Scrollable Content -->
      <section class="flex-1 overflow-auto p-6">
        <RouterView />
      </section>
    </main>
  </div>
</template>

<script setup lang="ts">
import { useRoute, RouterView, RouterLink } from 'vue-router'
import { LayoutDashboard, List, Map, Utensils, Settings, LogOut, ChevronDown, Bell, Search } from 'lucide-vue-next'

const route = useRoute()
</script>
