'use client';

import { useState, useMemo } from 'react';
import { Calendar as CalendarIcon, ChevronLeft, ChevronRight, Search, Plus, List as ListIcon, Map as MapIcon, Bell, Download, Filter, ChevronDown, MoreHorizontal, Phone, Users, MapPin } from 'lucide-react';
import { reservations as allReservations, tables } from '@/lib/mock-data';

const tableMap = new Map(tables.map(t => [t.code, t]));

const statusLabel: Record<string, string> = {
  Pending: 'Chờ đến',
  Arrived: 'Đã đến',
  Dining: 'Đang dùng',
  Completed: 'Hoàn tất',
  Cancelled: 'Đã hủy',
};

const statusStyle: Record<string, string> = {
  Pending: 'bg-amber-100 text-amber-700',
  Arrived: 'bg-blue-100 text-blue-700',
  Dining: 'bg-emerald-100 text-emerald-700',
  Completed: 'bg-slate-200 text-slate-600',
  Cancelled: 'bg-rose-100 text-rose-700',
};

const statusDotStyle: Record<string, string> = {
  Pending: 'bg-amber-400',
  Arrived: 'bg-blue-500',
  Dining: 'bg-emerald-500',
  Completed: 'bg-slate-400',
  Cancelled: 'bg-rose-400',
};

function formatDate(date: Date) {
  const dd = String(date.getDate()).padStart(2, '0');
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const yyyy = date.getFullYear();
  const dow = ['CN', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'][date.getDay()];
  return `${dow}, ${dd}/${mm}/${yyyy}`;
}

function toDateStr(date: Date) {
  const dd = String(date.getDate()).padStart(2, '0');
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const yyyy = date.getFullYear();
  return `${yyyy}-${mm}-${dd}`;
}

export default function ListPage() {
  const [selectedDate, setSelectedDate] = useState(() => new Date(2026, 5, 18));
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  const dateStr = toDateStr(selectedDate);

  const reservations = useMemo(
    () => allReservations
      .filter(r => r.date === dateStr)
      .filter(r => statusFilter === 'all' || r.status === statusFilter)
      .filter(r =>
        !search ||
        r.customerName.toLowerCase().includes(search.toLowerCase()) ||
        r.id.toLowerCase().includes(search.toLowerCase()) ||
        r.customerPhone.includes(search)
      )
      .sort((a, b) => a.time.localeCompare(b.time)),
    [dateStr, search, statusFilter]
  );

  const counts = useMemo(() => {
    const c: Record<string, number> = { all: 0 };
    for (const r of allReservations.filter(r => r.date === dateStr)) {
      c.all++;
      c[r.status] = (c[r.status] || 0) + 1;
    }
    return c;
  }, [dateStr]);

  const prevDay = () => setSelectedDate(d => new Date(d.getFullYear(), d.getMonth(), d.getDate() - 1));
  const nextDay = () => setSelectedDate(d => new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1));
  const goToday = () => setSelectedDate(new Date(2026, 5, 18));

  return (
    <div className="space-y-5">
      {/* Page Header */}
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Danh sách đặt bàn</h1>
          <p className="text-slate-500 text-sm mt-1">Tra cứu và quản lý toàn bộ đặt bàn theo ngày.</p>
        </div>
        <div className="flex items-center gap-2">
          <button className="flex items-center gap-2 px-3 py-2 bg-white border border-slate-200 rounded-lg text-sm font-medium text-slate-700 hover:bg-slate-50 shadow-sm">
            <Download size={16} />
            Xuất Excel
          </button>
          <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 shadow-sm shadow-blue-600/20">
            <Plus size={16} />
            Tạo đặt bàn mới
          </button>
        </div>
      </div>

      {/* Toolbar */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-3 flex flex-wrap items-center gap-3">
        {/* Date Picker */}
        <div className="flex items-center gap-1 bg-slate-50 rounded-xl px-1 py-1">
          <button onClick={prevDay} className="p-1.5 hover:bg-white rounded-lg transition-colors">
            <ChevronLeft size={18} className="text-slate-600" />
          </button>
          <button
            onClick={goToday}
            className="flex items-center gap-2 px-3 py-1.5 bg-white rounded-lg shadow-sm border border-slate-200"
          >
            <CalendarIcon size={16} className="text-blue-600" />
            <span className="font-semibold text-slate-800 text-sm whitespace-nowrap">{formatDate(selectedDate)}</span>
          </button>
          <button onClick={nextDay} className="p-1.5 hover:bg-white rounded-lg transition-colors">
            <ChevronRight size={18} className="text-slate-600" />
          </button>
        </div>

        {/* View Switcher */}
        <div className="flex items-center bg-slate-100 rounded-xl p-1">
          <a href="/" className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium text-slate-500 hover:text-slate-700">
            <MapIcon size={14} />
            Lịch
          </a>
          <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium bg-white text-blue-600 shadow-sm">
            <ListIcon size={14} />
            Danh sách
          </button>
        </div>

        {/* Search */}
        <div className="relative flex-1 min-w-[220px] max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
          <input
            type="text"
            placeholder="Tìm tên, SĐT, mã đặt..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full pl-9 pr-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
          />
        </div>

        {/* Status Filter */}
        <div className="flex gap-1 bg-slate-50 rounded-xl p-1 overflow-x-auto">
          {[
            { id: 'all', label: 'Tất cả' },
            { id: 'Pending', label: 'Chờ đến' },
            { id: 'Arrived', label: 'Đã đến' },
            { id: 'Dining', label: 'Đang dùng' },
            { id: 'Completed', label: 'Hoàn tất' },
            { id: 'Cancelled', label: 'Đã hủy' },
          ].map(s => (
            <button
              key={s.id}
              onClick={() => setStatusFilter(s.id)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all whitespace-nowrap flex items-center gap-1.5 ${
                statusFilter === s.id ? 'bg-blue-600 text-white shadow-sm' : 'text-slate-600 hover:bg-white'
              }`}
            >
              {s.id !== 'all' && (
                <span className={`w-1.5 h-1.5 rounded-full ${statusFilter === s.id ? 'bg-white' : statusDotStyle[s.id]}`} />
              )}
              {s.label} ({counts[s.id] || 0})
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <table className="w-full">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200">
              <th className="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider w-[40px]">
                <input type="checkbox" className="rounded border-slate-300" />
              </th>
              <th className="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Mã đặt</th>
              <th className="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Khách hàng</th>
              <th className="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Liên hệ</th>
              <th className="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Thời gian</th>
              <th className="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Khách</th>
              <th className="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Bàn</th>
              <th className="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Loại</th>
              <th className="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Nguồn</th>
              <th className="px-4 py-3 text-left text-[11px] font-bold text-slate-500 uppercase tracking-wider">Trạng thái</th>
              <th className="px-4 py-3 text-right text-[11px] font-bold text-slate-500 uppercase tracking-wider w-[60px]"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {reservations.length === 0 && (
              <tr>
                <td colSpan={11} className="py-16 text-center text-slate-400 text-sm">
                  Không có dữ liệu
                </td>
              </tr>
            )}
            {reservations.map(r => (
              <tr key={r.id} className="hover:bg-slate-50/60 transition-colors group">
                <td className="px-4 py-3">
                  <input type="checkbox" className="rounded border-slate-300" />
                </td>
                <td className="px-4 py-3">
                  <a href={`/order/${r.id}`} className="text-blue-600 font-mono text-xs font-semibold hover:underline">
                    {r.id}
                  </a>
                </td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-400 to-indigo-500 flex items-center justify-center text-white text-xs font-bold">
                      {r.customerName.charAt(r.customerName.length - 1)}
                    </div>
                    <div>
                      <div className="text-sm font-semibold text-slate-800">{r.customerName}</div>
                      {r.note && <div className="text-[11px] text-slate-400 truncate max-w-[180px]">{r.note}</div>}
                    </div>
                  </div>
                </td>
                <td className="px-4 py-3 text-xs text-slate-600">
                  <div className="flex items-center gap-1">
                    <Phone size={11} className="text-slate-400" />
                    {r.customerPhone}
                  </div>
                </td>
                <td className="px-4 py-3">
                  <span className="font-mono text-sm font-bold text-slate-800">{r.time}</span>
                </td>
                <td className="px-4 py-3">
                  <span className="inline-flex items-center gap-1 text-xs text-slate-700">
                    <Users size={11} className="text-slate-400" />
                    {r.guests}
                  </span>
                </td>
                <td className="px-4 py-3">
                  {r.tables.length > 0 ? (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-slate-100 rounded text-xs font-mono font-bold text-slate-700">
                      <MapPin size={10} className="text-slate-400" />
                      {r.tables.join(', ')}
                    </span>
                  ) : (
                    <span className="text-slate-300">—</span>
                  )}
                </td>
                <td className="px-4 py-3">
                  <span className="text-xs text-slate-600">{r.type || '—'}</span>
                </td>
                <td className="px-4 py-3">
                  <span className="text-xs text-slate-600">{r.source || '—'}</span>
                </td>
                <td className="px-4 py-3">
                  <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold ${statusStyle[r.status]}`}>
                    <span className={`w-1.5 h-1.5 rounded-full ${statusDotStyle[r.status]}`} />
                    {statusLabel[r.status]}
                  </span>
                </td>
                <td className="px-4 py-3 text-right">
                  <a href={`/order/${r.id}`} className="inline-flex items-center justify-center w-7 h-7 rounded-lg hover:bg-slate-100 text-slate-500 hover:text-blue-600">
                    <MoreHorizontal size={16} />
                  </a>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {/* Footer */}
        <div className="px-4 py-3 border-t border-slate-200 bg-slate-50/60 flex flex-wrap items-center justify-between gap-2 text-xs text-slate-500">
          <span>Hiển thị <b className="text-slate-700">{reservations.length}</b> / {counts.all || 0} kết quả</span>
          <div className="flex items-center gap-1">
            <button className="px-2.5 py-1 border border-slate-200 rounded-md bg-white hover:bg-slate-50 disabled:opacity-50">Trước</button>
            <button className="px-2.5 py-1 border border-slate-200 rounded-md bg-blue-600 text-white font-semibold">1</button>
            <button className="px-2.5 py-1 border border-slate-200 rounded-md bg-white hover:bg-slate-50">2</button>
            <button className="px-2.5 py-1 border border-slate-200 rounded-md bg-white hover:bg-slate-50">Sau</button>
          </div>
        </div>
      </div>
    </div>
  );
}
