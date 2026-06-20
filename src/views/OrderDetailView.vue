<template>
  <div class="space-y-5">
    <!-- Top action bar -->
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div class="flex items-center gap-3">
        <button
          @click="router.back()"
          class="p-2 rounded-lg hover:bg-slate-100 text-slate-600"
        >
          <ArrowLeft :size="18" />
        </button>
        <div>
          <div class="flex items-center gap-2">
            <h1 class="text-xl font-bold text-slate-900">Chi tiết đặt bàn</h1>
            <span :class="['px-2 py-0.5 rounded-full text-[11px] font-semibold border', statusStyle[reservation.status]]">
              {{ statusLabel[reservation.status] }}
            </span>
          </div>
          <div class="flex items-center gap-2 text-xs text-slate-500 mt-0.5">
            <span class="font-mono font-semibold text-blue-600">{{ reservation.id }}</span>
            <span>•</span>
            <span>Tạo lúc {{ new Date(reservation.createdAt).toLocaleString('vi-VN') }}</span>
          </div>
        </div>
      </div>

      <div class="flex items-center gap-2">
        <button class="p-2 rounded-lg border border-slate-200 hover:bg-slate-50 text-slate-600">
          <Printer :size="16" />
        </button>
        <button class="p-2 rounded-lg border border-slate-200 hover:bg-slate-50 text-slate-600">
          <MessageSquare :size="16" />
        </button>
        <button class="p-2 rounded-lg border border-slate-200 hover:bg-slate-50 text-slate-600">
          <MoreHorizontal :size="16" />
        </button>
        <button class="flex items-center gap-1.5 px-3 py-2 border border-slate-200 rounded-lg text-sm font-medium text-slate-700 hover:bg-slate-50">
          <Edit :size="14" />
          Sửa
        </button>
        <button class="flex items-center gap-1.5 px-3 py-2 bg-emerald-500 text-white rounded-lg text-sm font-semibold hover:bg-emerald-600 shadow-sm">
          <Check :size="14" />
          Đã đến
        </button>
        <button class="flex items-center gap-1.5 px-3 py-2 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 shadow-sm">
          <Save :size="14" />
          Lưu
        </button>
      </div>
    </div>

    <!-- Customer summary header -->
    <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-2xl p-5 text-white shadow-sm">
      <div class="flex flex-wrap items-center justify-between gap-4">
        <div class="flex items-center gap-4">
          <div class="w-16 h-16 rounded-full bg-white/20 backdrop-blur flex items-center justify-center text-2xl font-black border-2 border-white/30">
            {{ reservation.customerName.charAt(reservation.customerName.length - 1) }}
          </div>
          <div>
            <div class="text-xl font-bold">{{ reservation.customerName }}</div>
            <div class="flex items-center gap-3 text-sm text-blue-100 mt-1">
              <span class="flex items-center gap-1"><Phone :size="12" />{{ reservation.customerPhone }}</span>
              <span v-if="customer?.email" class="flex items-center gap-1"><Mail :size="12" />{{ customer.email }}</span>
              <span class="px-2 py-0.5 bg-white/20 rounded text-[11px] font-bold">
                {{ customer?.totalVisits || 0 }} lần đến
              </span>
            </div>
          </div>
        </div>
        <div class="grid grid-cols-3 gap-3 text-center">
          <div class="bg-white/10 backdrop-blur rounded-xl px-4 py-2">
            <div class="text-[10px] uppercase tracking-wider text-blue-100">Ngày</div>
            <div class="text-sm font-bold">{{ new Date(reservation.date).toLocaleDateString('vi-VN') }}</div>
          </div>
          <div class="bg-white/10 backdrop-blur rounded-xl px-4 py-2">
            <div class="text-[10px] uppercase tracking-wider text-blue-100">Giờ</div>
            <div class="text-sm font-bold font-mono">{{ reservation.time }}</div>
          </div>
          <div class="bg-white/10 backdrop-blur rounded-xl px-4 py-2">
            <div class="text-[10px] uppercase tracking-wider text-blue-100">Khách</div>
            <div class="text-sm font-bold">{{ reservation.guests }} người</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Tabs -->
    <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
      <div class="flex border-b border-slate-200 overflow-x-auto">
        <button
          v-for="tab in tabItems"
          :key="tab.id"
          @click="activeTab = tab.id"
          :class="[
            'flex items-center gap-2 px-5 py-3.5 text-sm font-semibold whitespace-nowrap transition-all border-b-2',
            activeTab === tab.id
              ? 'border-blue-600 text-blue-600 bg-blue-50/40'
              : 'border-transparent text-slate-600 hover:text-slate-800 hover:bg-slate-50'
          ]"
        >
          <component :is="tab.icon" :size="15" />
          {{ tab.label }}
        </button>
      </div>

      <div class="p-5">
        <!-- ── Tab: Thông tin đặt chỗ ── -->
        <div v-if="activeTab === 'info'" class="grid grid-cols-1 lg:grid-cols-3 gap-5">
          <div class="lg:col-span-2 space-y-5">
            <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
              <div class="px-5 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
                <div class="flex items-center gap-2">
                  <ClipboardList :size="16" class="text-blue-600" />
                  <h3 class="text-sm font-bold text-slate-700 uppercase tracking-wider">Thông tin đặt chỗ</h3>
                </div>
              </div>
              <div class="p-5">
                <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
                  <div>
                    <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Mã đặt chỗ</div>
                    <div class="text-sm text-slate-800 font-mono font-medium"><span class="text-blue-600">{{ reservation.id }}</span></div>
                  </div>
                  <div>
                    <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Ngày đặt</div>
                    <div class="text-sm text-slate-800 font-medium">{{ new Date(reservation.date).toLocaleDateString('vi-VN') }}</div>
                  </div>
                  <div>
                    <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Giờ đến</div>
                    <div class="text-sm text-emerald-600 font-bold font-mono">{{ reservation.time }}</div>
                  </div>
                  <div>
                    <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Số khách</div>
                    <div class="text-sm text-slate-800 font-medium flex items-center gap-1"><Users :size="14" />{{ reservation.guests }} người</div>
                  </div>
                  <div>
                    <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Loại tiệc</div>
                    <div class="text-sm text-slate-800 font-medium">{{ reservation.type || '—' }}</div>
                  </div>
                  <div>
                    <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Nguồn khách</div>
                    <div class="text-sm text-slate-800 font-medium">
                      <span class="inline-flex px-2 py-0.5 bg-indigo-100 text-indigo-700 rounded text-xs font-semibold">{{ reservation.source }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
              <div class="px-5 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
                <div class="flex items-center gap-2">
                  <MapPin :size="16" class="text-blue-600" />
                  <h3 class="text-sm font-bold text-slate-700 uppercase tracking-wider">Bàn được phân</h3>
                </div>
              </div>
              <div class="p-5">
                <div v-if="reservation.tables.length > 0" class="space-y-3">
                  <div class="flex flex-wrap gap-2">
                    <div v-for="t in reservation.tables" :key="t" class="px-3 py-2 bg-blue-50 border-2 border-blue-200 rounded-xl flex items-center gap-2">
                      <MapPin :size="14" class="text-blue-600" />
                      <span class="font-mono font-bold text-blue-700">{{ t }}</span>
                    </div>
                  </div>
                  <div v-if="zoneName" class="text-xs text-slate-500">
                    Khu vực: <b class="text-slate-700">{{ zoneName }}</b>
                  </div>
                </div>
                <div v-else class="text-sm text-slate-400 italic flex items-center gap-2">
                  <AlertCircle :size="14" />
                  Chưa phân bàn
                </div>
              </div>
            </div>

            <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
              <div class="px-5 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
                <div class="flex items-center gap-2">
                  <StickyNote :size="16" class="text-blue-600" />
                  <h3 class="text-sm font-bold text-slate-700 uppercase tracking-wider">Ghi chú</h3>
                </div>
              </div>
              <div class="p-5">
                <div v-if="reservation.note" class="text-sm text-slate-700 bg-amber-50 border border-amber-200 rounded-lg p-3">
                  {{ reservation.note }}
                </div>
                <div v-else class="text-sm text-slate-400 italic">Không có ghi chú</div>
              </div>
            </div>
          </div>

          <div class="space-y-5">
            <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
              <div class="px-5 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
                <div class="flex items-center gap-2">
                  <Tag :size="16" class="text-blue-600" />
                  <h3 class="text-sm font-bold text-slate-700 uppercase tracking-wider">Trạng thái</h3>
                </div>
              </div>
              <div class="p-5">
                <div class="space-y-3">
                  <div
                    v-for="s in statuses"
                    :key="s.id"
                    :class="[
                      'flex items-center gap-2 px-3 py-2 rounded-lg',
                      reservation.status === s.id
                        ? 'bg-blue-50 border-2 border-blue-300'
                        : 'bg-slate-50 border border-slate-100 opacity-60'
                    ]"
                  >
                    <div :class="['w-2 h-2 rounded-full', reservation.status === s.id ? 'bg-blue-500 animate-pulse' : 'bg-slate-300']" />
                    <span :class="['text-sm', reservation.status === s.id ? 'font-bold text-blue-700' : 'text-slate-600']">{{ s.label }}</span>
                    <Check v-if="reservation.status === s.id" :size="14" class="ml-auto text-blue-600" />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- ── Tab: Thông tin mở rộng ── -->
        <div v-if="activeTab === 'expanded'" class="space-y-5">
          <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            <div class="px-5 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
              <div class="flex items-center gap-2">
                <ClipboardList :size="16" class="text-blue-600" />
                <h3 class="text-sm font-bold text-slate-700 uppercase tracking-wider">Thông tin mở rộng</h3>
              </div>
            </div>
            <div class="p-5">
              <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
                <div>
                  <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Hình thức thanh toán</div>
                  <div class="text-sm text-slate-800 font-medium">Tiền mặt</div>
                </div>
                <div>
                  <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Đặt cọc</div>
                  <div class="text-sm text-slate-800 font-medium">0đ</div>
                </div>
                <div>
                  <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Yêu cầu đặc biệt</div>
                  <div class="text-sm text-slate-800 font-medium">{{ reservation.note || '—' }}</div>
                </div>
                <div>
                  <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Giờ kết thúc dự kiến</div>
                  <div class="text-sm text-slate-800 font-medium">—</div>
                </div>
                <div>
                  <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Số lượng trẻ em</div>
                  <div class="text-sm text-slate-800 font-medium">0</div>
                </div>
                <div>
                  <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Phương tiện</div>
                  <div class="text-sm text-slate-800 font-medium">— (Không xác định)</div>
                </div>
                <div>
                  <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Dịp kỷ niệm</div>
                  <div class="text-sm text-slate-800 font-medium">{{ reservation.type || '—' }}</div>
                </div>
                <div>
                  <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Hoa / Trang trí</div>
                  <div class="text-sm text-slate-800 font-medium">Không</div>
                </div>
                <div>
                  <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Ghi chú nội bộ</div>
                  <div class="text-sm text-slate-800 font-medium">—</div>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            <div class="px-5 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
              <div class="flex items-center gap-2">
                <Building :size="16" class="text-blue-600" />
                <h3 class="text-sm font-bold text-slate-700 uppercase tracking-wider">Hành chính</h3>
              </div>
            </div>
            <div class="p-5">
              <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
                <div>
                  <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Chi nhánh</div>
                  <div class="text-sm text-slate-800 font-medium">Ngưu Cát Quận 1</div>
                </div>
                <div>
                  <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Kênh tiếp nhận</div>
                  <div class="text-sm text-slate-800 font-medium">{{ reservation.source }}</div>
                </div>
                <div>
                  <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Nhân viên tạo</div>
                  <div class="text-sm text-slate-800 font-medium">Nguyễn Văn A</div>
                </div>
                <div>
                  <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Mã khách hàng</div>
                  <div class="text-sm text-slate-800 font-mono font-medium">{{ reservation.customerId }}</div>
                </div>
                <div>
                  <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Ngày tạo</div>
                  <div class="text-sm text-slate-800 font-medium">{{ new Date(reservation.createdAt).toLocaleString('vi-VN') }}</div>
                </div>
                <div>
                  <div class="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">Lần cập nhật cuối</div>
                  <div class="text-sm text-slate-800 font-medium">18/06/2026 11:32</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- ── Tab: Người tiếp nhận ── -->
        <div v-if="activeTab === 'receiver'" class="space-y-5">
          <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            <div class="px-5 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
              <div class="flex items-center gap-2">
                <UserPlus :size="16" class="text-blue-600" />
                <h3 class="text-sm font-bold text-slate-700 uppercase tracking-wider">Danh sách người phụ trách</h3>
              </div>
              <button class="flex items-center gap-1.5 px-3 py-1.5 bg-blue-600 text-white rounded-lg text-xs font-semibold hover:bg-blue-700">
                <Plus :size="12" />
                Thêm người
              </button>
            </div>
            <div class="p-5">
              <div class="divide-y divide-slate-100">
                <div v-for="(r, i) in receivers" :key="i" class="flex items-center gap-3 py-3 first:pt-0 last:pb-0">
                  <div class="w-10 h-10 rounded-full bg-gradient-to-br from-indigo-400 to-purple-500 flex items-center justify-center text-white text-sm font-bold">
                    {{ r.avatar }}
                  </div>
                  <div class="flex-1">
                    <div class="text-sm font-semibold text-slate-800">{{ r.name }}</div>
                    <div class="text-xs text-slate-500">{{ r.role }}</div>
                  </div>
                  <div class="text-xs text-slate-500 font-mono">{{ r.time }}</div>
                  <button class="p-1.5 rounded-lg hover:bg-slate-100 text-slate-400">
                    <MoreHorizontal :size="14" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- ── Tab: Lịch sử thao tác ── -->
        <div v-if="activeTab === 'operations'" class="space-y-5">
          <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            <div class="px-5 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
              <div class="flex items-center gap-2">
                <HistoryIcon :size="16" class="text-blue-600" />
                <h3 class="text-sm font-bold text-slate-700 uppercase tracking-wider">Lịch sử thao tác</h3>
              </div>
            </div>
            <div class="p-5">
              <div class="relative">
                <div class="absolute left-[19px] top-2 bottom-2 w-px bg-slate-200" />
                <div class="space-y-3">
                  <div v-for="(op, i) in operations" :key="i" class="flex items-start gap-3 relative">
                    <div :class="['w-10 h-10 rounded-full flex items-center justify-center shrink-0 z-10 border-4 border-white', typeColor[op.type]]">
                      <component :is="op.icon" :size="14" />
                    </div>
                    <div class="flex-1 pt-1">
                      <div class="text-sm font-semibold text-slate-800">{{ op.action }}</div>
                      <div class="text-xs text-slate-500 mt-0.5">
                        <b class="text-slate-700">{{ op.user }}</b> • {{ op.time }}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- ── Tab: Lịch sử tiêu dùng ── -->
        <div v-if="activeTab === 'consumption'">
          <div v-if="!order" class="text-center py-12 text-slate-400">
            <ShoppingBag :size="32" class="mx-auto mb-2" />
            <div class="text-sm">Chưa có lịch sử tiêu dùng</div>
          </div>
          <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-5">
            <div class="lg:col-span-2 space-y-5">
              <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                <div class="px-5 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
                  <div class="flex items-center gap-2">
                    <Receipt :size="16" class="text-blue-600" />
                    <h3 class="text-sm font-bold text-slate-700 uppercase tracking-wider">Chi tiết đơn hàng</h3>
                  </div>
                </div>
                <div class="p-5">
                  <table class="w-full">
                    <thead>
                      <tr class="border-b border-slate-200">
                        <th class="text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider pb-2">Món</th>
                        <th class="text-right text-[11px] font-bold text-slate-500 uppercase tracking-wider pb-2">SL</th>
                        <th class="text-right text-[11px] font-bold text-slate-500 uppercase tracking-wider pb-2">Đơn giá</th>
                        <th class="text-right text-[11px] font-bold text-slate-500 uppercase tracking-wider pb-2">Thành tiền</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                      <tr v-for="(it, i) in order.items" :key="i">
                        <td class="py-2.5 text-sm font-medium text-slate-800">{{ it.name }}</td>
                        <td class="py-2.5 text-right text-sm text-slate-700 font-mono">{{ it.quantity }}</td>
                        <td class="py-2.5 text-right text-sm text-slate-700 font-mono">{{ formatVND(it.price) }}</td>
                        <td class="py-2.5 text-right text-sm font-bold text-slate-900 font-mono">{{ formatVND(it.price * it.quantity) }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>

            <div class="space-y-5">
              <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                <div class="px-5 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
                  <div class="flex items-center gap-2">
                    <Receipt :size="16" class="text-blue-600" />
                    <h3 class="text-sm font-bold text-slate-700 uppercase tracking-wider">Tổng cộng</h3>
                  </div>
                </div>
                <div class="p-5">
                  <div class="space-y-2 text-sm">
                    <div class="flex justify-between">
                      <span class="text-slate-600">Tạm tính</span>
                      <span class="font-mono font-semibold text-slate-800">{{ formatVND(order.subtotal) }}</span>
                    </div>
                    <div class="flex justify-between">
                      <span class="text-slate-600">VAT (10%)</span>
                      <span class="font-mono font-semibold text-slate-800">{{ formatVND(order.vat) }}</span>
                    </div>
                    <div class="flex justify-between border-t border-slate-200 pt-2 mt-2">
                      <span class="font-bold text-slate-900">TỔNG CỘNG</span>
                      <span class="font-mono font-black text-blue-600 text-base">{{ formatVND(order.total) }}</span>
                    </div>
                  </div>
                </div>
              </div>

              <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                <div class="px-5 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
                  <div class="flex items-center gap-2">
                    <Tag :size="16" class="text-blue-600" />
                    <h3 class="text-sm font-bold text-slate-700 uppercase tracking-wider">Trạng thái đơn</h3>
                  </div>
                </div>
                <div class="p-5">
                  <div class="text-sm">
                    <span class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-emerald-100 text-emerald-700 rounded-full text-xs font-bold">
                      <Check :size="12" />
                      {{ order.status }}
                    </span>
                    <div class="text-xs text-slate-500 mt-2">
                      Tạo lúc {{ new Date(order.createdAt).toLocaleString('vi-VN') }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  ArrowLeft, Phone, MessageSquare, Edit, Save, Printer, MoreHorizontal,
  MapPin, Users, Tag, StickyNote, History as HistoryIcon,
  UserCheck, UserPlus, ShoppingBag, Receipt, Plus,
  Check, AlertCircle, Mail, Building, FileText, ClipboardList
} from 'lucide-vue-next'
import { reservations as allReservations, customers, orders, tables, zones } from '@/lib/mock-data'

const route = useRoute()
const router = useRouter()

const id = computed(() => route.params.id as string)

const reservation = computed(() => {
  return allReservations.find(r => r.id === id.value) || allReservations[0]
})

const customer = computed(() => {
  return customers.find(c => c.id === reservation.value.customerId)
})

const order = computed(() => {
  return orders.find(o => o.reservationId === reservation.value.id)
})

const zone = computed(() => {
  return reservation.value.tables[0] ? tables.find(t => t.code === reservation.value.tables[0])?.zoneId : null
})

const zoneName = computed(() => {
  return zone.value ? zones.find(z => z.id === zone.value)?.name : null
})

const activeTab = ref('info')

const tabItems = [
  { id: 'info', label: 'TT-Đặt chỗ', icon: FileText },
  { id: 'expanded', label: 'TT-Mở rộng', icon: ClipboardList },
  { id: 'receiver', label: 'Người tiếp nhận', icon: UserPlus },
  { id: 'operations', label: 'Lịch sử thao tác', icon: HistoryIcon },
  { id: 'consumption', label: 'Lịch sử tiêu dùng', icon: ShoppingBag },
]

const statusLabel: Record<string, string> = {
  Pending: 'Chờ đến',
  Arrived: 'Đã đến',
  Dining: 'Đang dùng',
  Completed: 'Hoàn tất',
  Cancelled: 'Đã hủy',
}

const statusStyle: Record<string, string> = {
  Pending: 'bg-amber-100 text-amber-700 border-amber-200',
  Arrived: 'bg-blue-100 text-blue-700 border-blue-200',
  Dining: 'bg-emerald-100 text-emerald-700 border-emerald-200',
  Completed: 'bg-slate-200 text-slate-600 border-slate-300',
  Cancelled: 'bg-rose-100 text-rose-700 border-rose-200',
}

const statuses = [
  { id: 'Pending', label: 'Chờ đến' },
  { id: 'Arrived', label: 'Đã đến' },
  { id: 'Dining', label: 'Đang dùng' },
  { id: 'Completed', label: 'Hoàn tất' },
  { id: 'Cancelled', label: 'Đã hủy' },
]

const receivers = [
  { name: 'Lễ tân Ngọc Trâm', role: 'Tiếp nhận đặt bàn', time: '17/06/2026 14:00', avatar: 'NT' },
  { name: 'Quản lý ca Trần Hùng', role: 'Xác nhận đặt bàn', time: '17/06/2026 14:25', avatar: 'TH' },
  { name: 'Phục vụ Mai Linh', role: 'Phụ trách bàn', time: '18/06/2026 11:25', avatar: 'ML' },
]

const operations = computed(() => [
  { time: '18/06/2026 11:30', user: 'Mai Linh', action: 'Đánh dấu khách đã đến', type: 'success', icon: UserCheck },
  { time: '18/06/2026 11:25', user: 'Hệ thống', action: 'Tự động phân bàn A02', type: 'info', icon: MapPin },
  { time: '17/06/2026 16:45', user: 'Ngọc Trâm', action: 'Xác nhận đặt bàn', type: 'success', icon: Check },
  { time: '17/06/2026 14:00', user: 'Ngọc Trâm', action: `Tạo đặt bàn mới (${reservation.value.id})`, type: 'create', icon: Plus },
])

const typeColor: Record<string, string> = {
  success: 'bg-emerald-100 text-emerald-700',
  info: 'bg-blue-100 text-blue-700',
  create: 'bg-indigo-100 text-indigo-700',
}

function formatVND(n: number) {
  return n.toLocaleString('vi-VN') + 'đ'
}
</script>
