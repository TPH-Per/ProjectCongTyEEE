<template>
  <div class="min-h-screen bg-gray-50 p-6">
    <!-- Page Header -->
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-800">Quản lý Giá Vốn (COGS)</h1>
      <p class="text-sm text-gray-500 mt-1">Tháng 6 / 2026 · Cập nhật lần cuối: hôm nay</p>
    </div>

    <!-- Summary Bar -->
    <div class="grid grid-cols-3 gap-4 mb-6">
      <div class="kawaii-card p-5">
        <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-1">Doanh Thu Tháng</p>
        <p class="text-2xl font-bold text-gray-800">198,000,000<span class="text-base font-normal text-gray-500">đ</span></p>
        <p class="text-xs text-green-500 mt-1 font-medium">▲ 8.4% so với tháng trước</p>
      </div>
      <div class="kawaii-card p-5">
        <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-1">Tổng COGS</p>
        <p class="text-2xl font-bold text-gray-800">69,300,000<span class="text-base font-normal text-gray-500">đ</span></p>
        <p class="text-xs text-gray-400 mt-1 font-medium">Chi phí nguyên liệu thuần</p>
      </div>
      <div class="kawaii-card p-5">
        <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-1">COGS Ratio</p>
        <div class="flex items-center gap-3 mt-1">
          <p class="text-2xl font-bold text-gray-800">35%</p>
          <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-green-100 text-green-700">✓ Tốt (&lt;40%)</span>
        </div>
        <!-- Mini progress bar -->
        <div class="mt-3 bg-gray-100 rounded-full h-2">
          <div class="h-2 rounded-full bg-green-400" style="width: 35%"></div>
        </div>
        <div class="flex justify-between text-xs text-gray-400 mt-1">
          <span>0%</span><span class="text-green-600 font-semibold">35%</span><span>100%</span>
        </div>
      </div>
    </div>

    <!-- COGS Item Table -->
    <div class="kawaii-card mb-6 overflow-hidden">
      <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
        <div>
          <h2 class="text-base font-bold text-gray-800">Danh Sách Món & COGS</h2>
          <p class="text-xs text-gray-400 mt-0.5">Click tiêu đề cột để sắp xếp</p>
        </div>
        <button class="kawaii-btn-primary text-sm px-4 py-2 flex items-center gap-1.5">
          <span class="text-lg leading-none">+</span> Thêm Món
        </button>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead class="bg-gray-50">
            <tr>
              <th
                v-for="col in tableColumns"
                :key="col.key"
                class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100 select-none whitespace-nowrap"
              >
                {{ col.label }}
                <span class="ml-1 text-gray-300">↕</span>
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-50">
            <tr
              v-for="(item, idx) in cogsItems"
              :key="idx"
              class="hover:bg-orange-50 transition-colors duration-100"
            >
              <td class="px-4 py-3 font-medium text-gray-800 whitespace-nowrap">{{ item.name }}</td>
              <td class="px-4 py-3">
                <input
                  :value="item.cost"
                  class="w-28 text-right bg-gray-100 rounded-lg px-3 py-1.5 text-sm text-gray-700 border-0 focus:outline-none focus:ring-2 focus:ring-pink-300"
                  readonly
                />
              </td>
              <td class="px-4 py-3">
                <input
                  :value="item.price"
                  class="w-28 text-right bg-gray-100 rounded-lg px-3 py-1.5 text-sm text-gray-700 border-0 focus:outline-none focus:ring-2 focus:ring-pink-300"
                  readonly
                />
              </td>
              <td class="px-4 py-3">
                <input
                  :value="item.qty"
                  class="w-20 text-center bg-gray-100 rounded-lg px-3 py-1.5 text-sm text-gray-700 border-0 focus:outline-none focus:ring-2 focus:ring-pink-300"
                  readonly
                />
              </td>
              <td class="px-4 py-3 text-gray-600 text-right whitespace-nowrap">{{ item.unitCOGS }}</td>
              <td class="px-4 py-3 font-semibold text-gray-800 text-right whitespace-nowrap">{{ item.totalCOGS }}</td>
              <td class="px-4 py-3">
                <span
                  class="inline-block px-2.5 py-0.5 rounded-full text-xs font-bold"
                  :class="item.ratioBadge"
                >
                  {{ item.ratio }}
                </span>
              </td>
            </tr>
            <!-- Footer row -->
            <tr class="bg-gray-50 font-bold">
              <td class="px-4 py-3 text-gray-700">Tổng</td>
              <td colspan="4" class="px-4 py-3"></td>
              <td class="px-4 py-3 text-right text-gray-800">29,360,000đ</td>
              <td class="px-4 py-3"></td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Bottom row: Bar chart + Note -->
    <div class="grid grid-cols-3 gap-4">
      <!-- COGS by Category Bar Chart -->
      <div class="col-span-2 kawaii-card p-5">
        <h2 class="text-base font-bold text-gray-800 mb-4">COGS Theo Danh Mục</h2>
        <div class="space-y-4">
          <div v-for="cat in cogsCategories" :key="cat.label">
            <div class="flex justify-between items-center mb-1.5">
              <span class="text-sm font-medium text-gray-700">{{ cat.label }}</span>
              <span class="text-sm font-bold text-gray-800">{{ cat.pct }}%</span>
            </div>
            <div class="w-full bg-gray-100 rounded-full h-3 overflow-hidden">
              <div
                class="h-3 rounded-full transition-all duration-700"
                :style="{ width: cat.pct + '%', backgroundColor: cat.color }"
              ></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Note / Alert box -->
      <div class="flex flex-col gap-4">
        <div class="kawaii-card p-5 border-l-4 border-red-400 bg-red-50 flex-1">
          <div class="flex items-start gap-3">
            <span class="text-2xl">⚠️</span>
            <div>
              <p class="text-sm font-bold text-red-700 mb-1">Cảnh báo COGS cao</p>
              <p class="text-sm text-red-600 leading-relaxed">
                Món <strong>Rượu Sake Chín</strong> có COGS vượt 50% (56.2%), cần kiểm tra lại định giá hoặc thương lượng lại giá nhập.
              </p>
            </div>
          </div>
        </div>
        <div class="kawaii-card p-5 bg-blue-50 border-l-4 border-blue-300">
          <p class="text-xs font-bold text-blue-700 mb-1">💡 Gợi Ý</p>
          <p class="text-xs text-blue-600 leading-relaxed">
            Tỷ lệ COGS tổng thể <strong>35%</strong> đang trong ngưỡng an toàn. Mục tiêu dưới 38% cho quý này.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const tableColumns = [
  { key: 'name', label: 'Tên Món' },
  { key: 'cost', label: 'Giá Cost (đ)' },
  { key: 'price', label: 'Giá Bán (đ)' },
  { key: 'qty', label: 'Định Lượng (phần/ngày)' },
  { key: 'unitCOGS', label: 'COGS Đơn Vị' },
  { key: 'totalCOGS', label: 'Tổng COGS' },
  { key: 'ratio', label: 'COGS%' },
]

const cogsItems = [
  {
    name: 'Thăn Ngoại Wagyu',
    cost: '180,000đ',
    price: '500,000đ',
    qty: '45',
    unitCOGS: '180,000đ',
    totalCOGS: '8,100,000đ',
    ratio: '36%',
    ratioBadge: 'bg-yellow-100 text-yellow-700',
  },
  {
    name: 'Lưỡi Bò Thượng Hạng',
    cost: '120,000đ',
    price: '400,000đ',
    qty: '38',
    unitCOGS: '120,000đ',
    totalCOGS: '4,560,000đ',
    ratio: '30%',
    ratioBadge: 'bg-green-100 text-green-700',
  },
  {
    name: 'Dẻ Sườn Bò',
    cost: '95,000đ',
    price: '380,000đ',
    qty: '60',
    unitCOGS: '95,000đ',
    totalCOGS: '5,700,000đ',
    ratio: '25%',
    ratioBadge: 'bg-green-100 text-green-700',
  },
  {
    name: 'Nấm Nhật Kiểu',
    cost: '25,000đ',
    price: '120,000đ',
    qty: '80',
    unitCOGS: '25,000đ',
    totalCOGS: '2,000,000đ',
    ratio: '20.8%',
    ratioBadge: 'bg-green-100 text-green-700',
  },
  {
    name: 'Rượu Sake Chín',
    cost: '450,000đ',
    price: '800,000đ',
    qty: '20',
    unitCOGS: '450,000đ',
    totalCOGS: '9,000,000đ',
    ratio: '56.2%',
    ratioBadge: 'bg-red-100 text-red-700',
  },
]

const cogsCategories = [
  { label: 'Thịt Bò', pct: 45, color: '#FF7B89' },
  { label: 'Hải Sản', pct: 22, color: '#60A5FA' },
  { label: 'Đồ Uống', pct: 18, color: '#A78BFA' },
  { label: 'Rau Củ & Nấm', pct: 15, color: '#34D399' },
]
</script>
