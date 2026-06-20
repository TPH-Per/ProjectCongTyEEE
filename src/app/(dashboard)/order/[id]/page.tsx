'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft, Phone, MessageSquare, Edit, Save, X, Printer, MoreHorizontal,
  User, MapPin, Calendar, Clock, Users, Tag, StickyNote, History,
  UserCheck, UserPlus, ClipboardList, ShoppingBag, Receipt, Plus,
  Check, AlertCircle, ChevronRight, Mail, Building, FileText
} from 'lucide-react';
import { reservations as allReservations, customers, orders, menuItems, tables, zones } from '@/lib/mock-data';

const tabItems = [
  { id: 'info', label: 'TT-Đặt chỗ', icon: FileText },
  { id: 'expanded', label: 'TT-Mở rộng', icon: ClipboardList },
  { id: 'receiver', label: 'Người tiếp nhận', icon: UserPlus },
  { id: 'operations', label: 'Lịch sử thao tác', icon: History },
  { id: 'consumption', label: 'Lịch sử tiêu dùng', icon: ShoppingBag },
];

const statusLabel: Record<string, string> = {
  Pending: 'Chờ đến',
  Arrived: 'Đã đến',
  Dining: 'Đang dùng',
  Completed: 'Hoàn tất',
  Cancelled: 'Đã hủy',
};

const statusStyle: Record<string, string> = {
  Pending: 'bg-amber-100 text-amber-700 border-amber-200',
  Arrived: 'bg-blue-100 text-blue-700 border-blue-200',
  Dining: 'bg-emerald-100 text-emerald-700 border-emerald-200',
  Completed: 'bg-slate-200 text-slate-600 border-slate-300',
  Cancelled: 'bg-rose-100 text-rose-700 border-rose-200',
};

function formatVND(n: number) {
  return n.toLocaleString('vi-VN') + 'đ';
}

function Field({ label, value, mono }: { label: string; value: React.ReactNode; mono?: boolean }) {
  return (
    <div>
      <div className="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1">{label}</div>
      <div className={`text-sm text-slate-800 ${mono ? 'font-mono' : ''} font-medium`}>{value || '—'}</div>
    </div>
  );
}

function SectionCard({ title, icon: Icon, children, action }: any) {
  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
      <div className="px-5 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
        <div className="flex items-center gap-2">
          {Icon && <Icon size={16} className="text-blue-600" />}
          <h3 className="text-sm font-bold text-slate-700 uppercase tracking-wider">{title}</h3>
        </div>
        {action}
      </div>
      <div className="p-5">{children}</div>
    </div>
  );
}

export default function BookingDetailPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const id = params?.id as string;
  const reservation = allReservations.find(r => r.id === id) || allReservations[0];
  const customer = customers.find(c => c.id === reservation.customerId);
  const order = orders.find(o => o.reservationId === reservation.id);
  const zone = reservation.tables[0] ? tables.find(t => t.code === reservation.tables[0])?.zoneId : null;
  const zoneName = zone ? zones.find(z => z.id === zone)?.name : null;

  const [activeTab, setActiveTab] = useState('info');

  return (
    <div className="space-y-5">
      {/* Top action bar */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <button
            onClick={() => router.back()}
            className="p-2 rounded-lg hover:bg-slate-100 text-slate-600"
          >
            <ArrowLeft size={18} />
          </button>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-bold text-slate-900">Chi tiết đặt bàn</h1>
              <span className={`px-2 py-0.5 rounded-full text-[11px] font-semibold border ${statusStyle[reservation.status]}`}>
                {statusLabel[reservation.status]}
              </span>
            </div>
            <div className="flex items-center gap-2 text-xs text-slate-500 mt-0.5">
              <span className="font-mono font-semibold text-blue-600">{reservation.id}</span>
              <span>•</span>
              <span>Tạo lúc {new Date(reservation.createdAt).toLocaleString('vi-VN')}</span>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button className="p-2 rounded-lg border border-slate-200 hover:bg-slate-50 text-slate-600">
            <Printer size={16} />
          </button>
          <button className="p-2 rounded-lg border border-slate-200 hover:bg-slate-50 text-slate-600">
            <MessageSquare size={16} />
          </button>
          <button className="p-2 rounded-lg border border-slate-200 hover:bg-slate-50 text-slate-600">
            <MoreHorizontal size={16} />
          </button>
          <button className="flex items-center gap-1.5 px-3 py-2 border border-slate-200 rounded-lg text-sm font-medium text-slate-700 hover:bg-slate-50">
            <Edit size={14} />
            Sửa
          </button>
          <button className="flex items-center gap-1.5 px-3 py-2 bg-emerald-500 text-white rounded-lg text-sm font-semibold hover:bg-emerald-600 shadow-sm">
            <Check size={14} />
            Đã đến
          </button>
          <button className="flex items-center gap-1.5 px-3 py-2 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 shadow-sm">
            <Save size={14} />
            Lưu
          </button>
        </div>
      </div>

      {/* Customer summary header */}
      <div className="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-2xl p-5 text-white shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 rounded-full bg-white/20 backdrop-blur flex items-center justify-center text-2xl font-black border-2 border-white/30">
              {reservation.customerName.charAt(reservation.customerName.length - 1)}
            </div>
            <div>
              <div className="text-xl font-bold">{reservation.customerName}</div>
              <div className="flex items-center gap-3 text-sm text-blue-100 mt-1">
                <span className="flex items-center gap-1"><Phone size={12} />{reservation.customerPhone}</span>
                {customer?.email && <span className="flex items-center gap-1"><Mail size={12} />{customer.email}</span>}
                <span className="px-2 py-0.5 bg-white/20 rounded text-[11px] font-bold">
                  {customer?.totalVisits || 0} lần đến
                </span>
              </div>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-3 text-center">
            <div className="bg-white/10 backdrop-blur rounded-xl px-4 py-2">
              <div className="text-[10px] uppercase tracking-wider text-blue-100">Ngày</div>
              <div className="text-sm font-bold">{new Date(reservation.date).toLocaleDateString('vi-VN')}</div>
            </div>
            <div className="bg-white/10 backdrop-blur rounded-xl px-4 py-2">
              <div className="text-[10px] uppercase tracking-wider text-blue-100">Giờ</div>
              <div className="text-sm font-bold font-mono">{reservation.time}</div>
            </div>
            <div className="bg-white/10 backdrop-blur rounded-xl px-4 py-2">
              <div className="text-[10px] uppercase tracking-wider text-blue-100">Khách</div>
              <div className="text-sm font-bold">{reservation.guests} người</div>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="flex border-b border-slate-200 overflow-x-auto">
          {tabItems.map(tab => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-2 px-5 py-3.5 text-sm font-semibold whitespace-nowrap transition-all border-b-2 ${
                  isActive
                    ? 'border-blue-600 text-blue-600 bg-blue-50/40'
                    : 'border-transparent text-slate-600 hover:text-slate-800 hover:bg-slate-50'
                }`}
              >
                <Icon size={15} />
                {tab.label}
              </button>
            );
          })}
        </div>

        <div className="p-5">
          {activeTab === 'info' && <TabInfo reservation={reservation} zoneName={zoneName} />}
          {activeTab === 'expanded' && <TabExpanded reservation={reservation} />}
          {activeTab === 'receiver' && <TabReceiver reservation={reservation} />}
          {activeTab === 'operations' && <TabOperations reservation={reservation} />}
          {activeTab === 'consumption' && <TabConsumption reservation={reservation} order={order} />}
        </div>
      </div>
    </div>
  );
}

// ── Tab: Thông tin đặt chỗ ──
function TabInfo({ reservation, zoneName }: any) {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
      <div className="lg:col-span-2 space-y-5">
        <SectionCard title="Thông tin đặt chỗ" icon={ClipboardList}>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            <Field label="Mã đặt chỗ" value={<span className="text-blue-600">{reservation.id}</span>} mono />
            <Field label="Ngày đặt" value={new Date(reservation.date).toLocaleDateString('vi-VN')} />
            <Field label="Giờ đến" value={<span className="text-emerald-600 font-bold font-mono">{reservation.time}</span>} mono />
            <Field label="Số khách" value={<span className="flex items-center gap-1"><Users size={14} />{reservation.guests} người</span>} />
            <Field label="Loại tiệc" value={reservation.type} />
            <Field label="Nguồn khách" value={
              <span className="inline-flex px-2 py-0.5 bg-indigo-100 text-indigo-700 rounded text-xs font-semibold">{reservation.source}</span>
            } />
          </div>
        </SectionCard>

        <SectionCard title="Bàn được phân" icon={MapPin}>
          {reservation.tables.length > 0 ? (
            <div className="space-y-3">
              <div className="flex flex-wrap gap-2">
                {reservation.tables.map((t: string) => (
                  <div key={t} className="px-3 py-2 bg-blue-50 border-2 border-blue-200 rounded-xl flex items-center gap-2">
                    <MapPin size={14} className="text-blue-600" />
                    <span className="font-mono font-bold text-blue-700">{t}</span>
                  </div>
                ))}
              </div>
              {zoneName && (
                <div className="text-xs text-slate-500">
                  Khu vực: <b className="text-slate-700">{zoneName}</b>
                </div>
              )}
            </div>
          ) : (
            <div className="text-sm text-slate-400 italic flex items-center gap-2">
              <AlertCircle size={14} />
              Chưa phân bàn
            </div>
          )}
        </SectionCard>

        <SectionCard title="Ghi chú" icon={StickyNote}>
          {reservation.note ? (
            <div className="text-sm text-slate-700 bg-amber-50 border border-amber-200 rounded-lg p-3">
              {reservation.note}
            </div>
          ) : (
            <div className="text-sm text-slate-400 italic">Không có ghi chú</div>
          )}
        </SectionCard>
      </div>

      <div className="space-y-5">
        <SectionCard title="Trạng thái" icon={Tag}>
          <div className="space-y-3">
            {[
              { s: 'Pending', label: 'Chờ đến' },
              { s: 'Arrived', label: 'Đã đến' },
              { s: 'Dining', label: 'Đang dùng' },
              { s: 'Completed', label: 'Hoàn tất' },
              { s: 'Cancelled', label: 'Đã hủy' },
            ].map(({ s, label }) => {
              const active = reservation.status === s;
              return (
                <div key={s} className={`flex items-center gap-2 px-3 py-2 rounded-lg ${active ? 'bg-blue-50 border-2 border-blue-300' : 'bg-slate-50 border border-slate-100 opacity-60'}`}>
                  <div className={`w-2 h-2 rounded-full ${active ? 'bg-blue-500 animate-pulse' : 'bg-slate-300'}`} />
                  <span className={`text-sm ${active ? 'font-bold text-blue-700' : 'text-slate-600'}`}>{label}</span>
                  {active && <Check size={14} className="ml-auto text-blue-600" />}
                </div>
              );
            })}
          </div>
        </SectionCard>
      </div>
    </div>
  );
}

// ── Tab: Thông tin mở rộng ──
function TabExpanded({ reservation }: any) {
  return (
    <div className="space-y-5">
      <SectionCard title="Thông tin mở rộng" icon={ClipboardList}>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <Field label="Hình thức thanh toán" value="Tiền mặt" />
          <Field label="Đặt cọc" value="0đ" />
          <Field label="Yêu cầu đặc biệt" value={reservation.note || '—'} />
          <Field label="Giờ kết thúc dự kiến" value="—" />
          <Field label="Số lượng trẻ em" value="0" />
          <Field label="Phương tiện" value="— (Không xác định)" />
          <Field label="Dịp kỷ niệm" value={reservation.type} />
          <Field label="Hoa / Trang trí" value="Không" />
          <Field label="Ghi chú nội bộ" value="—" />
        </div>
      </SectionCard>

      <SectionCard title="Hành chính" icon={Building}>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          <Field label="Chi nhánh" value="Ngưu Cát Quận 1" />
          <Field label="Kênh tiếp nhận" value={reservation.source} />
          <Field label="Nhân viên tạo" value="Nguyễn Văn A" />
          <Field label="Mã khách hàng" value={reservation.customerId} mono />
          <Field label="Ngày tạo" value={new Date(reservation.createdAt).toLocaleString('vi-VN')} />
          <Field label="Lần cập nhật cuối" value="18/06/2026 11:32" />
        </div>
      </SectionCard>
    </div>
  );
}

// ── Tab: Người tiếp nhận ──
function TabReceiver({ reservation }: any) {
  const receivers = [
    { name: 'Lễ tân Ngọc Trâm', role: 'Tiếp nhận đặt bàn', time: '17/06/2026 14:00', avatar: 'NT' },
    { name: 'Quản lý ca Trần Hùng', role: 'Xác nhận đặt bàn', time: '17/06/2026 14:25', avatar: 'TH' },
    { name: 'Phục vụ Mai Linh', role: 'Phụ trách bàn', time: '18/06/2026 11:25', avatar: 'ML' },
  ];
  return (
    <div className="space-y-5">
      <SectionCard
        title="Danh sách người phụ trách"
        icon={UserPlus}
        action={
          <button className="flex items-center gap-1.5 px-3 py-1.5 bg-blue-600 text-white rounded-lg text-xs font-semibold hover:bg-blue-700">
            <Plus size={12} />
            Thêm người
          </button>
        }
      >
        <div className="divide-y divide-slate-100">
          {receivers.map((r, i) => (
            <div key={i} className="flex items-center gap-3 py-3 first:pt-0 last:pb-0">
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-indigo-400 to-purple-500 flex items-center justify-center text-white text-sm font-bold">
                {r.avatar}
              </div>
              <div className="flex-1">
                <div className="text-sm font-semibold text-slate-800">{r.name}</div>
                <div className="text-xs text-slate-500">{r.role}</div>
              </div>
              <div className="text-xs text-slate-500 font-mono">{r.time}</div>
              <button className="p-1.5 rounded-lg hover:bg-slate-100 text-slate-400">
                <MoreHorizontal size={14} />
              </button>
            </div>
          ))}
        </div>
      </SectionCard>
    </div>
  );
}

// ── Tab: Lịch sử thao tác ──
function TabOperations({ reservation }: any) {
  const operations = [
    { time: '18/06/2026 11:30', user: 'Mai Linh', action: 'Đánh dấu khách đã đến', type: 'success', icon: UserCheck },
    { time: '18/06/2026 11:25', user: 'Hệ thống', action: 'Tự động phân bàn A02', type: 'info', icon: MapPin },
    { time: '17/06/2026 16:45', user: 'Ngọc Trâm', action: 'Xác nhận đặt bàn', type: 'success', icon: Check },
    { time: '17/06/2026 14:00', user: 'Ngọc Trâm', action: `Tạo đặt bàn mới (${reservation.id})`, type: 'create', icon: Plus },
  ];
  const typeColor: Record<string, string> = {
    success: 'bg-emerald-100 text-emerald-700',
    info: 'bg-blue-100 text-blue-700',
    create: 'bg-indigo-100 text-indigo-700',
  };
  return (
    <SectionCard title="Lịch sử thao tác" icon={History}>
      <div className="relative">
        <div className="absolute left-[19px] top-2 bottom-2 w-px bg-slate-200" />
        <div className="space-y-3">
          {operations.map((op, i) => {
            const Icon = op.icon;
            return (
              <div key={i} className="flex items-start gap-3 relative">
                <div className={`w-10 h-10 rounded-full ${typeColor[op.type]} flex items-center justify-center shrink-0 z-10 border-4 border-white`}>
                  <Icon size={14} />
                </div>
                <div className="flex-1 pt-1">
                  <div className="text-sm font-semibold text-slate-800">{op.action}</div>
                  <div className="text-xs text-slate-500 mt-0.5">
                    <b className="text-slate-700">{op.user}</b> • {op.time}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </SectionCard>
  );
}

// ── Tab: Lịch sử tiêu dùng ──
function TabConsumption({ reservation, order }: any) {
  if (!order) {
    return (
      <div className="text-center py-12 text-slate-400">
        <ShoppingBag size={32} className="mx-auto mb-2" />
        <div className="text-sm">Chưa có lịch sử tiêu dùng</div>
      </div>
    );
  }
  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
      <div className="lg:col-span-2 space-y-5">
        <SectionCard title="Chi tiết đơn hàng" icon={Receipt}>
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-200">
                <th className="text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider pb-2">Món</th>
                <th className="text-right text-[11px] font-bold text-slate-500 uppercase tracking-wider pb-2">SL</th>
                <th className="text-right text-[11px] font-bold text-slate-500 uppercase tracking-wider pb-2">Đơn giá</th>
                <th className="text-right text-[11px] font-bold text-slate-500 uppercase tracking-wider pb-2">Thành tiền</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {order.items.map((it: any, i: number) => (
                <tr key={i}>
                  <td className="py-2.5 text-sm font-medium text-slate-800">{it.name}</td>
                  <td className="py-2.5 text-right text-sm text-slate-700 font-mono">{it.quantity}</td>
                  <td className="py-2.5 text-right text-sm text-slate-700 font-mono">{formatVND(it.price)}</td>
                  <td className="py-2.5 text-right text-sm font-bold text-slate-900 font-mono">{formatVND(it.price * it.quantity)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </SectionCard>
      </div>

      <div className="space-y-5">
        <SectionCard title="Tổng cộng" icon={Receipt}>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-slate-600">Tạm tính</span>
              <span className="font-mono font-semibold text-slate-800">{formatVND(order.subtotal)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-600">VAT (10%)</span>
              <span className="font-mono font-semibold text-slate-800">{formatVND(order.vat)}</span>
            </div>
            <div className="flex justify-between border-t border-slate-200 pt-2 mt-2">
              <span className="font-bold text-slate-900">TỔNG CỘNG</span>
              <span className="font-mono font-black text-blue-600 text-base">{formatVND(order.total)}</span>
            </div>
          </div>
        </SectionCard>

        <SectionCard title="Trạng thái đơn" icon={Tag}>
          <div className="text-sm">
            <span className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-emerald-100 text-emerald-700 rounded-full text-xs font-bold">
              <Check size={12} />
              {order.status}
            </span>
            <div className="text-xs text-slate-500 mt-2">
              Tạo lúc {new Date(order.createdAt).toLocaleString('vi-VN')}
            </div>
          </div>
        </SectionCard>
      </div>
    </div>
  );
}
