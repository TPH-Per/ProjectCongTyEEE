<template>
  <div class="space-y-6">
    <!-- Page Header -->
    <div class="flex items-start justify-between">
      <div>
        <h1 class="text-2xl font-black text-[hsl(var(--foreground))] tracking-tight">{{ t('auto_t_n_kho_h_ng_ng_y') }}</h1>
        <p class="text-sm text-[hsl(var(--muted-foreground))] mt-1">{{ t('auto__________qu_n_l__nguy_n_li_u__') }}</p>
      </div>
      <div class="flex gap-2">
        <button class="kawaii-btn-ghost px-4 py-2 text-sm font-bold flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" x2="12" y1="15" y2="3"/></svg>
          Xuất CSV
        </button>
        <button class="kawaii-btn-primary px-4 py-2 text-sm font-bold flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
          Gửi Hóa Đơn Đỏ
        </button>
      </div>
    </div>

    <!-- Date & Summary -->
    <div class="flex gap-4">
      <div class="kawaii-card p-4 flex items-center gap-3 flex-1">
        <input type="date" value="2026-06-20" class="kawaii-input py-2 text-sm w-40" />
        <span class="text-sm text-gray-500">{{ t('auto_ng_y_xu_t_kho') }}</span>
      </div>
      <div class="kawaii-card p-4 flex items-center gap-4 flex-1">
        <div class="text-center">
          <div class="text-[10px] text-gray-500 font-bold uppercase">{{ t('auto_t_ng_nguy_n_li_u') }}</div>
          <div class="text-xl font-black text-[hsl(var(--foreground))]">47 SKU</div>
        </div>
        <div class="w-px h-8 bg-[hsl(var(--border))]" />
        <div class="text-center">
          <div class="text-[10px] text-gray-500 font-bold uppercase">{{ t('auto_t_ng_gi__tr__xu_t') }}</div>
          <div class="text-xl font-black text-[hsl(var(--primary))]">{{ t('auto_69_300_000_') }}</div>
        </div>
        <div class="w-px h-8 bg-[hsl(var(--border))]" />
        <div class="text-center">
          <div class="text-[10px] text-gray-500 font-bold uppercase">{{ t('auto_tr_ng_th_i') }}</div>
          <div class="px-2 py-1 bg-yellow-100 text-yellow-800 text-xs font-bold rounded-full">{{ t('auto_ch__x_c_nh_n') }}</div>
        </div>
      </div>
    </div>

    <!-- Inventory Categories -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Category: Thịt Bò -->
      <div class="kawaii-card overflow-hidden">
        <div class="kawaii-card-header">
          <span class="font-bold text-sm text-[hsl(var(--foreground))]">{{ t('auto____th_t_b___beef_') }}</span>
          <span class="kawaii-pill bg-red-100 text-red-700">{{ t('auto_9_lo_i') }}</span>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-[hsl(var(--border))]">
                <th class="text-left py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_nguy_n_li_u') }}</th>
                <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_t_n___u') }}</th>
                <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_xu_t_b_p') }}</th>
                <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_t_n_cu_i') }}</th>
                <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto___n_gi_') }}</th>
                <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_th_nh_ti_n') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-[hsl(var(--border))]">
              <tr v-for="item in beefItems" :key="item.name" class="hover:bg-[hsl(var(--muted))]/50">
                <td class="py-2.5 px-4 font-semibold text-[hsl(var(--foreground))]">{{ item.name }}</td>
                <td class="py-2.5 px-4 text-right text-gray-500">{{ item.openStock }} kg</td>
                <td class="py-2.5 px-4 text-right font-bold text-orange-600">{{ item.used }} kg</td>
                <td class="py-2.5 px-4 text-right text-gray-600">{{ item.closeStock }} kg</td>
                <td class="py-2.5 px-4 text-right text-gray-500">{{ item.price.toLocaleString() }}đ</td>
                <td class="py-2.5 px-4 text-right font-bold text-[hsl(var(--foreground))]">{{ (item.used * item.price).toLocaleString() }}đ</td>
              </tr>
            </tbody>
            <tfoot>
              <tr class="bg-[hsl(var(--muted))]/60 font-bold">
                <td class="py-2.5 px-4 text-[hsl(var(--foreground))]" colspan="5">{{ t('auto_t_ng_th_t_b_') }}</td>
                <td class="py-2.5 px-4 text-right text-[hsl(var(--primary))] font-black">{{ t('auto_31_410_000_') }}</td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>

      <!-- Category: Đồ Uống -->
      <div class="kawaii-card overflow-hidden">
        <div class="kawaii-card-header">
          <span class="font-bold text-sm text-[hsl(var(--foreground))]">{{ t('auto_______u_ng__beverage_') }}</span>
          <span class="kawaii-pill bg-purple-100 text-purple-700">{{ t('auto_6_lo_i') }}</span>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-[hsl(var(--border))]">
                <th class="text-left py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_nguy_n_li_u') }}</th>
                <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_t_n___u') }}</th>
                <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_xu_t_b_n') }}</th>
                <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_t_n_cu_i') }}</th>
                <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto___n_gi_') }}</th>
                <th class="text-right py-2 px-4 font-bold text-gray-500 text-[11px] uppercase">{{ t('auto_th_nh_ti_n') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-[hsl(var(--border))]">
              <tr v-for="item in beverageItems" :key="item.name" class="hover:bg-[hsl(var(--muted))]/50">
                <td class="py-2.5 px-4 font-semibold text-[hsl(var(--foreground))]">{{ item.name }}</td>
                <td class="py-2.5 px-4 text-right text-gray-500">{{ item.openStock }}</td>
                <td class="py-2.5 px-4 text-right font-bold text-purple-600">{{ item.used }}</td>
                <td class="py-2.5 px-4 text-right text-gray-600">{{ item.closeStock }}</td>
                <td class="py-2.5 px-4 text-right text-gray-500">{{ item.price.toLocaleString() }}đ</td>
                <td class="py-2.5 px-4 text-right font-bold text-[hsl(var(--foreground))]">{{ (item.used * item.price).toLocaleString() }}đ</td>
              </tr>
            </tbody>
            <tfoot>
              <tr class="bg-[hsl(var(--muted))]/60 font-bold">
                <td class="py-2.5 px-4 text-[hsl(var(--foreground))]" colspan="5">{{ t('auto_t_ng____u_ng') }}</td>
                <td class="py-2.5 px-4 text-right text-purple-600 font-black">{{ t('auto_12_560_000_') }}</td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>
    </div>

    <!-- Red Invoice Summary -->
    <div class="kawaii-card p-6">
      <h3 class="font-bold text-base text-[hsl(var(--foreground))] mb-4 flex items-center gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-red-500"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" x2="8" y1="13" y2="13"/><line x1="16" x2="8" y1="17" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
        Tổng Kết Xuất Hóa Đơn Đỏ — Ngày 20/06/2026
      </h3>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <div class="bg-red-50 border border-red-100 rounded-xl p-3 text-center">
          <div class="text-xs font-bold text-red-400 uppercase mb-1">{{ t('auto_b_a_t_i__dinner_') }}</div>
          <div class="font-black text-lg text-red-700">{{ t('auto_7_200_000_') }}</div>
        </div>
        <div class="bg-orange-50 border border-orange-100 rounded-xl p-3 text-center">
          <div class="text-xs font-bold text-orange-400 uppercase mb-1">{{ t('auto_b_a_tr_a__lunch_') }}</div>
          <div class="font-black text-lg text-orange-700">{{ t('auto_3_400_000_') }}</div>
        </div>
        <div class="bg-purple-50 border border-purple-100 rounded-xl p-3 text-center">
          <div class="text-xs font-bold text-purple-400 uppercase mb-1">{{ t('auto_r__u_wine') }}</div>
          <div class="font-black text-lg text-purple-700">{{ t('auto_1_100_000_') }}</div>
        </div>
        <div class="bg-blue-50 border border-blue-100 rounded-xl p-3 text-center">
          <div class="text-xs font-bold text-blue-400 uppercase mb-1">Delivery</div>
          <div class="font-black text-lg text-blue-700">{{ t('auto_700_000_') }}</div>
        </div>
      </div>
      <div class="flex items-center justify-between bg-[hsl(var(--muted))] rounded-xl p-4">
        <div>
          <div class="font-black text-lg text-[hsl(var(--foreground))]">{{ t('auto_t_ng_doanh_thu_c_n_xu_t_h____') }}</div>
          <div class="text-sm text-gray-500">{{ t('auto_bao_g_m_vat_8_') }}</div>
        </div>
        <div class="text-3xl font-black text-[hsl(var(--primary))]">{{ t('auto_12_400_000_') }}</div>
      </div>
      <div class="flex gap-3 mt-4">
        <button class="kawaii-btn-ghost px-4 py-2 text-sm font-bold flex-1">
          Tải Mẫu XML (Cục Thuế)
        </button>
        <button class="kawaii-btn-primary px-6 py-2 text-sm font-bold flex-1">
          Gửi Dữ Liệu Lên Cục Thuế
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
const beefItems = [
  { name: 'Thăn Ngoại Wagyu A5', openStock: 12, used: 8.5, closeStock: 3.5, price: 900000 },
  { name: 'Lưỡi Bò Thượng Hạng', openStock: 8, used: 5, closeStock: 3, price: 400000 },
  { name: 'Dẻ Sườn Bò Rút Xương', openStock: 15, used: 10, closeStock: 5, price: 380000 },
  { name: 'Ba Chỉ Bò Hoa', openStock: 10, used: 7, closeStock: 3, price: 320000 },
]

const beverageItems = [
  { name: 'Rượu Sake Juyondai', openStock: 24, used: 18, closeStock: 6, price: 450000 },
  { name: 'Bia Asahi (lon)', openStock: 120, used: 87, closeStock: 33, price: 30000 },
  { name: 'Nước Ngọt Assorted', openStock: 200, used: 145, closeStock: 55, price: 15000 },
]
</script>
