'use client';

import { useState, useMemo } from 'react';
import { Calendar as CalendarIcon, ChevronLeft, ChevronRight, Search, Plus, List, Map as MapIcon, Bell } from 'lucide-react';
import { reservations as allReservations, zones, tables } from '@/lib/mock-data';

const tableZoneMap = new Map(tables.map(t => [t.code, t.zoneId]));

const timeSlots = [
  { id: 'morning', label: 'Sáng', range: '06:00 - 11:00', start: 6, end: 11 },
  { id: 'noon', label: 'Trưa', range: '11:00 - 14:00', start: 11, end: 14 },
  { id: 'afternoon', label: 'Chiều', range: '14:00 - 17:00', start: 14, end: 17 },
  { id: 'evening', label: 'Tối', range: '17:00 - 22:00', start: 17, end: 24 },
];

function getTimeSlot(time: string) {
  const h = parseInt(time.split(':')[0], 10);
  for (const s of timeSlots) {
    if (h >= s.start && h < s.end) return s.id;
  }
  return 'evening';
}

function getReservationZoneId(tableCodes: string[]): string | null {
  for (const code of tableCodes) {
    const z = tableZoneMap.get(code);
    if (z) return z;
  }
  return null;
}

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

const statusLabel: Record<string, string> = {
  Pending: 'Chờ đến',
  Arrived: 'Đã đến',
  Dining: 'Đang dùng',
  Completed: 'Hoàn tất',
  Cancelled: 'Đã hủy',
};

const statusCardStyle: Record<string, { bg: string; border: string; badge: string; text: string }> = {
  Pending: { bg: 'bg-amber-50', border: 'border-amber-300', badge: 'bg-amber-400 text-white', text: 'text-amber-900' },
  Arrived: { bg: 'bg-blue-50', border: 'border-blue-300', badge: 'bg-blue-500 text-white', text: 'text-blue-900' },
  Dining: { bg: 'bg-emerald-50', border: 'border-emerald-300', badge: 'bg-emerald-500 text-white', text: 'text-emerald-900' },
  Completed: { bg: 'bg-slate-50', border: 'border-slate-300', badge: 'bg-slate-400 text-white', text: 'text-slate-700' },
  Cancelled: { bg: 'bg-rose-50', border: 'border-rose-200', badge: 'bg-rose-400 text-white', text: 'text-rose-700' },
};

const slotHeaderBg: Record<string, string> = {
  morning: 'bg-amber-50',
  noon: 'bg-orange-50',
  afternoon: 'bg-sky-50',
  evening: 'bg-indigo-50',
};

const slotCellBg: Record<string, string> = {
  morning: 'bg-amber-50/30',
  noon: 'bg-orange-50/30',
  afternoon: 'bg-sky-50/30',
  evening: 'bg-indigo-50/30',
};

const slotDot: Record<string, string> = {
  morning: 'bg-amber-400',
  noon: 'bg-orange-400',
  afternoon: 'bg-sky-400',
  evening: 'bg-indigo-400',
};

export default function TimelinePage() {
  const [selectedDate, setSelectedDate] = useState(() => new Date(2026, 5, 18));
  const [selectedTab, setSelectedTab] = useState('all');
  const [search, setSearch] = useState('');

  const dateStr = toDateStr(selectedDate);
  const formatted = formatDate(selectedDate);

  const todayReservations = useMemo(
    () =>
      allReservations
        .filter(r => r.date === dateStr && r.status !== 'Cancelled')
        .filter(r =>
          !search ||
          r.customerName.toLowerCase().includes(search.toLowerCase()) ||
          r.id.toLowerCase().includes(search.toLowerCase()) ||
          r.customerPhone.includes(search)
        )
        .sort((a, b) => a.time.localeCompare(b.time)),
    [dateStr, search]
  );

  const gridData = useMemo(() => {
    const data: Record<string, Record<string, typeof allReservations>> = {};
    for (const zone of zones) {
      data[zone.id] = {};
      for (const slot of timeSlots) data[zone.id][slot.id] = [];
    }
    for (const r of todayReservations) {
      const zoneId = getReservationZoneId(r.tables);
      const slot = getTimeSlot(r.time);
      if (zoneId && data[zoneId]) data[zoneId][slot].push(r);
    }
    return data;
  }, [todayReservations]);

  const zoneCounts = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const r of todayReservations) {
      const zoneId = getReservationZoneId(r.tables);
      if (zoneId) counts[zoneId] = (counts[zoneId] || 0) + 1;
    }
    return counts;
  }, [todayReservations]);

  const totalCount = todayReservations.length;

  const prevDay = () => setSelectedDate(d => new Date(d.getFullYear(), d.getMonth(), d.getDate() - 1));
  const nextDay = () => setSelectedDate(d => new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1));
  const goToday = () => setSelectedDate(new Date(2026, 5, 18));

  const filteredZones = selectedTab === 'all' ? zones : zones.filter(z => z.id === selectedTab);

  return (
    <div className="space-y-5">
      {/* Page Header */}
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Lịch đặt bàn</h1>
          <p className="text-slate-500 text-sm mt-1">Theo dõi và quản lý lịch đặt bàn theo khung giờ trong ngày.</p>
        </div>
        <div className="flex items-center gap-2">
          <button className="flex items-center gap-2 px-3 py-2 bg-white border border-slate-200 rounded-lg text-sm font-medium text-slate-700 hover:bg-slate-50 shadow-sm">
            <Bell size={16} />
            Thông báo
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
            <span className="font-semibold text-slate-800 text-sm whitespace-nowrap">{formatted}</span>
          </button>
          <button onClick={nextDay} className="p-1.5 hover:bg-white rounded-lg transition-colors">
            <ChevronRight size={18} className="text-slate-600" />
          </button>
        </div>

        {/* View Switcher */}
        <div className="flex items-center bg-slate-100 rounded-xl p-1">
          <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium bg-white text-blue-600 shadow-sm">
            <MapIcon size={14} />
            Lịch
          </button>
          <a href="/list" className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium text-slate-500 hover:text-slate-700">
            <List size={14} />
            Danh sách
          </a>
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

        {/* Zone Tabs */}
        <div className="flex gap-1 bg-slate-50 rounded-xl p-1 w-full md:w-auto overflow-x-auto">
          <button
            onClick={() => setSelectedTab('all')}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all whitespace-nowrap ${
              selectedTab === 'all' ? 'bg-blue-600 text-white shadow-sm' : 'text-slate-600 hover:bg-white'
            }`}
          >
            Tất cả ({totalCount})
          </button>
          {zones.map(zone => (
            <button
              key={zone.id}
              onClick={() => setSelectedTab(zone.id)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all whitespace-nowrap flex items-center gap-1.5 ${
                selectedTab === zone.id ? 'bg-blue-600 text-white shadow-sm' : 'text-slate-600 hover:bg-white'
              }`}
            >
              <span
                className="w-2 h-2 rounded-full shrink-0"
                style={{ backgroundColor: selectedTab === zone.id ? 'white' : zone.color }}
              />
              {zone.name} ({zoneCounts[zone.id] || 0})
            </button>
          ))}
        </div>
      </div>

      {/* Timeline Grid */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="grid" style={{ gridTemplateColumns: '160px repeat(4, minmax(140px, 1fr))' }}>
          {/* Header row */}
          <div className="px-4 py-3 bg-slate-50 border-b border-r border-slate-200 flex items-center">
            <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">Khu vực</span>
          </div>
          {timeSlots.map(slot => (
            <div key={slot.id} className={`${slotHeaderBg[slot.id]} border-b border-r border-slate-200 last:border-r-0 px-3 py-3`}>
              <div className="flex items-center gap-1.5 mb-0.5">
                <span className={`w-1.5 h-1.5 rounded-full ${slotDot[slot.id]}`} />
                <span className="text-xs font-bold text-slate-700">{slot.label}</span>
              </div>
              <div className="text-[10px] text-slate-500 font-medium">{slot.range}</div>
            </div>
          ))}

          {/* Rows */}
          {filteredZones.map(zone => (
            <div key={zone.id} className="contents">
              <div className="px-4 py-3 bg-slate-50/50 border-b border-r border-slate-200 flex items-center gap-2">
                <div className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: zone.color }} />
                <div>
                  <div className="text-sm font-bold text-slate-800">{zone.name}</div>
                  <div className="text-[10px] text-slate-400 font-medium">{zoneCounts[zone.id] || 0} đặt bàn</div>
                </div>
              </div>
              {timeSlots.map(slot => {
                const items = gridData[zone.id]?.[slot.id] || [];
                return (
                  <div
                    key={slot.id}
                    className={`${slotCellBg[slot.id]} border-b border-r border-slate-100 last:border-r-0 p-2 align-top min-h-[140px]`}
                  >
                    <div className="flex flex-col gap-1.5 min-h-[124px]">
                      {items.length === 0 && (
                        <div className="flex-1 flex items-center justify-center min-h-[60px]">
                          <span className="text-[10px] text-slate-300 italic">—</span>
                        </div>
                      )}
                      {items.map(r => {
                        const s = statusCardStyle[r.status];
                        return (
                          <div
                            key={r.id}
                            className={`${s.bg} ${s.border} border-l-[3px] rounded-md px-2 py-1.5 cursor-pointer transition-all hover:shadow-md`}
                          >
                            <div className="flex items-center justify-between gap-1 mb-0.5">
                              <span className={`text-[11px] font-bold truncate leading-tight ${s.text}`}>
                                {r.customerName}
                              </span>
                              <span className={`shrink-0 px-1.5 py-0.5 rounded text-[9px] font-bold leading-none ${s.badge}`}>
                                {statusLabel[r.status]}
                              </span>
                            </div>
                            <div className="flex items-center gap-1.5 text-[10px] text-slate-600 flex-wrap">
                              <span className="font-mono font-bold">{r.time}</span>
                              <span className="text-slate-300">•</span>
                              <span>{r.guests} khách</span>
                              {r.tables.length > 0 && (
                                <>
                                  <span className="text-slate-300">•</span>
                                  <span className="font-mono font-bold text-slate-700">{r.tables.join(',')}</span>
                                </>
                              )}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                );
              })}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
