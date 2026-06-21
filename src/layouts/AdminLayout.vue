<template>
  <div class="flex h-screen overflow-hidden bg-[hsl(var(--background))]">
    <!-- Sidebar -->
    <aside class="w-64 border-r border-[hsl(var(--border))] bg-white flex flex-col shrink-0">
      <div class="p-5 border-b border-[hsl(var(--border))]">
        <div class="flex items-center gap-2.5">
          <div class="w-10 h-10 rounded-2xl bg-gray-900 flex items-center justify-center text-white font-black text-base shadow-md">
            NC
          </div>
          <div>
            <h1 class="text-sm font-black text-[hsl(var(--foreground))] tracking-tight">NGƯU CÁT</h1>
            <p class="text-[10px] text-[hsl(var(--muted-foreground))] font-bold uppercase tracking-wider">Admin Portal</p>
          </div>
        </div>
      </div>

      <nav class="flex-1 px-3 space-y-1 py-4 overflow-y-auto">
        <div class="text-[10px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider px-3 mb-1">
          Hệ Thống
        </div>

        <RouterLink to="/admin/dashboard" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/admin/dashboard' ? 'bg-gray-100 text-gray-900 font-extrabold border-gray-200' : 'text-gray-600 hover:bg-gray-50'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>
          <span>Tổng Quan Hệ Thống</span>
        </RouterLink>

        <RouterLink to="/admin/accounts" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/admin/accounts' ? 'bg-gray-100 text-gray-900 font-extrabold border-gray-200' : 'text-gray-600 hover:bg-gray-50'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          <span>Quản Lý Tài Khoản</span>
        </RouterLink>

        <div class="text-[10px] font-extrabold text-[hsl(var(--muted-foreground))] uppercase tracking-wider px-3 mb-1 mt-5">
          Cấu Hình Dữ Liệu
        </div>

        <RouterLink to="/admin/menus" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/admin/menus' ? 'bg-gray-100 text-gray-900 font-extrabold border-gray-200' : 'text-gray-600 hover:bg-gray-50'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"/><path d="M7 2v20"/><path d="M21 15V2v0a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7"/></svg>
          <span>Thực Đơn & Gói Menu</span>
        </RouterLink>

        <RouterLink to="/admin/floors" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/admin/floors' ? 'bg-gray-100 text-gray-900 font-extrabold border-gray-200' : 'text-gray-600 hover:bg-gray-50'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><line x1="3" x2="21" y1="9" y2="9"/><line x1="9" x2="9" y1="21" y2="9"/></svg>
          <span>Sơ Đồ Bàn (Floor Plan)</span>
        </RouterLink>

        <RouterLink to="/admin/kpi" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/admin/kpi' ? 'bg-gray-100 text-gray-900 font-extrabold border-gray-200' : 'text-gray-600 hover:bg-gray-50'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m12 14 4-4"/><path d="M3.34 19a10 10 0 1 1 17.32 0"/></svg>
          <span>Cấu Hình KPI/KGI</span>
        </RouterLink>
        
        <RouterLink to="/admin/audit" class="flex items-center gap-3 px-3 py-2.5 rounded-2xl transition-all text-sm font-semibold border border-transparent"
          :class="$route.path === '/admin/audit' ? 'bg-gray-100 text-gray-900 font-extrabold border-gray-200' : 'text-gray-600 hover:bg-gray-50'">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="3" rx="2"/><path d="M7 7h.01"/><path d="M7 12h.01"/><path d="M7 17h.01"/><path d="M11 7h6"/><path d="M11 12h6"/><path d="M11 17h6"/></svg>
          <span>Nhật Ký Hệ Thống (Audit)</span>
        </RouterLink>
      </nav>

      <div class="p-3 border-t border-[hsl(var(--border))] space-y-1">
        <div class="flex items-center gap-2.5 px-3 py-2 rounded-2xl bg-gray-900">
          <div class="w-9 h-9 rounded-full bg-white flex items-center justify-center text-gray-900 text-sm font-black">AD</div>
          <div class="flex-1 min-w-0">
            <div class="text-xs font-extrabold text-white truncate">System Admin</div>
            <div class="text-[10px] text-gray-400 font-semibold">Super User</div>
          </div>
        </div>
      </div>
    </aside>

    <main class="flex-1 flex flex-col overflow-hidden">
      <header class="h-16 border-b border-[hsl(var(--border))] bg-white flex items-center justify-between px-6 shrink-0">
        <div class="flex items-center gap-3">
          <h2 class="text-lg font-bold text-gray-800">Quản Trị Hệ Thống</h2>
        </div>
        <div class="flex items-center gap-3">
          <button class="relative p-2 rounded-2xl hover:bg-[hsl(var(--muted))] transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
          </button>
        </div>
      </header>
      <section class="flex-1 overflow-auto p-6 bg-gray-50/50">
        <RouterView />
      </section>
    </main>
  </div>
</template>

<script setup lang="ts">
import { RouterView, RouterLink, useRoute } from 'vue-router'
const $route = useRoute()
</script>
