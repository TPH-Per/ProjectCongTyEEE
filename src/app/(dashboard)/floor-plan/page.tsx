'use client';

import { useState, useMemo } from 'react';
import { Calendar as CalendarIcon, ChevronLeft, ChevronRight, Search, Users, MapPin, Clock, X, Check, ChevronRight as ChevronRightIcon, RotateCcw, Filter, Layers } from 'lucide-react';
import { tables as allTables, zones, reservations as allReservations } from '@/lib/mock-data';

const reservationByTable = new Map<string, typeof allReservations[0]>();
for (const r of allReservations) {
  if (r.status !== 'Cancelled') {
    for (const t of r.tables) {
      if (!reservationByTable.has(t)) reservationByTable.set(t, r);
    }
  }
}

const tableStatusStyle: Record<string, { bg: string; border: string; text: string; label: string; badge: string }> = {
  available: { bg: 'bg-white', border: 'border-emerald-200', text: 'text-emerald-700', label: 'Trống', badge: 'bg-emerald-100 text-emerald-700' },
  reserved: { bg: 'bg-amber-50', border: 'border-amber-300', text: 'text-amber-700', label: 'Đã đặt', badge: 'bg-amber-100 text-amber-700' },
  occupied: { bg: 'bg-rose-50', border: 'border-rose-300', text: 'text-rose-700', label: 'Đang ngồi', badge: 'bg-rose-100 text-rose-700' },
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

export default function FloorPlanPage() {
  const [selectedDate, setSelectedDate] = useState(() => new Date(2026, 5, 18));
  const [selectedZone, setSelectedZone] = useState<string>('Z003'); // Default selected (VIP) like the image
  const [mode, setMode] = useState<'default' | 'realtime'>('default');

  const dateStr = toDateStr(selectedDate);

  // Compute table status based on date and mode
  const tablesWithStatus = useMemo(() => {
    const reservedOnDate = new Set<string>();
    const occupiedOnDate = new Set<string>();
    for (const r of allReservations) {
      if (r.date !== dateStr || r.status === 'Cancelled') continue;
      if (r.status === 'Pending') {
        for (const t of r.tables) reservedOnDate.add(t);
      } else if (r.status === 'Arrived' || r.status === 'Dining' || r.status === 'Completed') {
        for (const t of r.tables) occupiedOnDate.add(t);
      }
    }
    return allTables.map(t => {
      let status: 'available' | 'reserved' | 'occupied' = t.status;
      if (mode === 'default') {
        if (occupiedOnDate.has(t.code)) status = 'occupied';
        else if (reservedOnDate.has(t.code)) status = 'reserved';
        else status = 'available';
      } else {
        status = t.status;
      }
      return { ...t, status };
    });
  }, [dateStr, mode]);

  // Per-zone stats
  const zoneStats = useMemo(() => {
    const stats: Record<string, { total: number; available: number; reserved: number; occupied: number }> = {};
    for (const z of zones) {
      stats[z.id] = { total: 0, available: 0, reserved: 0, occupied: 0 };
    }
    for (const t of tablesWithStatus) {
      if (stats[t.zoneId]) {
        stats[t.zoneId].total++;
        stats[t.zoneId][t.status]++;
      }
    }
    return stats;
  }, [tablesWithStatus]);

  const totalStats = useMemo(() => {
    const c = { total: 0, available: 0, reserved: 0, occupied: 0 };
    for (const t of tablesWithStatus) {
      c.total++;
      c[t.status]++;
    }
    return c;
  }, [tablesWithStatus]);

  const selectedZoneObj = zones.find(z => z.id === selectedZone);
  const zoneTables = useMemo(
    () => tablesWithStatus.filter(t => t.zoneId === selectedZone),
    [selectedZone, tablesWithStatus]
  );

  const prevDay = () => setSelectedDate(d => new Date(d.getFullYear(), d.getMonth(), d.getDate() - 1));
  const nextDay = () => setSelectedDate(d => new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1));
  const goToday = () => setSelectedDate(new Date(2026, 5, 18));

  return (
    <div className="space-y-5">
      {/* Page Header */}
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Sơ đồ bàn</h1>
          <p className="text-slate-500 text-sm mt-1">
            {mode === 'default'
              ? 'Xem tất cả các ngày theo ngày tháng — trạng thái bàn theo lịch đặt.'
              : 'Trạng thái bàn theo thời gian thực — cập nhật liên tức.'}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex items-center bg-white rounded-xl border border-slate-200 shadow-sm p-1">
            <button
              onClick={() => setMode('default')}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                mode === 'default' ? 'bg-blue-600 text-white shadow-sm' : 'text-slate-600'
              }`}
            >
              Theo ngày
            </button>
            <button
              onClick={() => setMode('realtime')}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all flex items-center gap-1.5 ${
                mode === 'realtime' ? 'bg-rose-500 text-white shadow-sm' : 'text-slate-600'
              }`}
            >
              <span className={`w-1.5 h-1.5 rounded-full ${mode === 'realtime' ? 'bg-white animate-pulse' : 'bg-rose-500 animate-pulse'}`} />
              Hiện tại
            </button>
          </div>
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

        {/* Status Legend */}
        <div className="flex items-center gap-3 text-xs ml-auto">
          <div className="flex items-center gap-1.5">
            <span className="w-3 h-3 rounded bg-emerald-100 border border-emerald-300" />
            <span className="font-semibold text-slate-700">{totalStats.available}</span>
            <span className="text-slate-500">Trống</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-3 h-3 rounded bg-amber-100 border border-amber-300" />
            <span className="font-semibold text-slate-700">{totalStats.reserved}</span>
            <span className="text-slate-500">Đã đặt</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-3 h-3 rounded bg-rose-100 border border-rose-300" />
            <span className="font-semibold text-slate-700">{totalStats.occupied}</span>
            <span className="text-slate-500">Đang ngồi</span>
          </div>
        </div>
      </div>

      {/* Main content - 2 columns: Area selector + Zone tables */}
      <div className="grid grid-cols-12 gap-5">
        {/* Left: Area Selector Panel */}
        <div className="col-span-12 lg:col-span-4 xl:col-span-3 space-y-4">
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            <div className="px-4 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
              <div className="flex items-center gap-2">
                <Layers size={15} className="text-blue-600" />
                <h3 className="text-sm font-bold text-slate-700 uppercase tracking-wider">Chọn khu vực</h3>
              </div>
              <span className="text-[10px] text-slate-400 font-semibold">
                {zones.length} khu vực
              </span>
            </div>

            <div className="p-2">
              {zones.map(z => {
                const s = zoneStats[z.id];
                const isActive = selectedZone === z.id;
                return (
                  <button
                    key={z.id}
                    onClick={() => setSelectedZone(z.id)}
                    className={`w-full text-left px-3 py-2.5 rounded-xl mb-1 transition-all flex items-center gap-3 group ${
                      isActive
                        ? 'bg-blue-50 border-2 border-blue-300 shadow-sm'
                        : 'hover:bg-slate-50 border-2 border-transparent'
                    }`}
                  >
                    {/* Checkbox */}
                    <div
                      className={`w-5 h-5 rounded-md border-2 flex items-center justify-center shrink-0 transition-all ${
                        isActive
                          ? 'bg-blue-600 border-blue-600'
                          : 'border-slate-300 group-hover:border-slate-400'
                      }`}
                    >
                      {isActive && <Check size={12} className="text-white" strokeWidth={3} />}
                    </div>

                    {/* Color dot */}
                    <span
                      className="w-3 h-3 rounded-full shrink-0 ring-2 ring-white"
                      style={{ backgroundColor: z.color, boxShadow: `0 0 0 2px ${z.color}30` }}
                    />

                    {/* Zone name + count */}
                    <div className="flex-1 min-w-0">
                      <div className={`text-sm font-semibold truncate ${isActive ? 'text-blue-700' : 'text-slate-800'}`}>
                        {z.name}
                      </div>
                      <div className="text-[11px] text-slate-500 font-medium">
                        {s.total} bàn • {s.available} trống
                      </div>
                    </div>

                    {/* Status mini badges */}
                    <div className="flex items-center gap-0.5 shrink-0">
                      {s.available > 0 && (
                        <span className="text-[10px] font-bold text-emerald-700 bg-emerald-50 px-1.5 py-0.5 rounded">
                          {s.available}
                        </span>
                      )}
                      {s.reserved > 0 && (
                        <span className="text-[10px] font-bold text-amber-700 bg-amber-50 px-1.5 py-0.5 rounded">
                          {s.reserved}
                        </span>
                      )}
                      {s.occupied > 0 && (
                        <span className="text-[10px] font-bold text-rose-700 bg-rose-50 px-1.5 py-0.5 rounded">
                          {s.occupied}
                        </span>
                      )}
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Selected zone summary card */}
          {selectedZoneObj && (
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
              <div className="px-4 py-3 border-b border-slate-100 bg-slate-50/60">
                <div className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">Khu vực đang chọn</div>
              </div>
              <div className="p-4 space-y-3">
                <div className="flex items-center gap-2">
                  <span
                    className="w-4 h-4 rounded-full shrink-0"
                    style={{ backgroundColor: selectedZoneObj.color }}
                  />
                  <div className="text-base font-bold text-slate-800">{selectedZoneObj.name}</div>
                </div>
                <div className="grid grid-cols-3 gap-2 text-center">
                  <div className="bg-emerald-50 border border-emerald-100 rounded-lg p-2">
                    <div className="text-lg font-black text-emerald-700">{zoneStats[selectedZoneObj.id]?.available || 0}</div>
                    <div className="text-[10px] text-emerald-600 font-semibold uppercase">Trống</div>
                  </div>
                  <div className="bg-amber-50 border border-amber-100 rounded-lg p-2">
                    <div className="text-lg font-black text-amber-700">{zoneStats[selectedZoneObj.id]?.reserved || 0}</div>
                    <div className="text-[10px] text-amber-600 font-semibold uppercase">Đặt</div>
                  </div>
                  <div className="bg-rose-50 border border-rose-100 rounded-lg p-2">
                    <div className="text-lg font-black text-rose-700">{zoneStats[selectedZoneObj.id]?.occupied || 0}</div>
                    <div className="text-[10px] text-rose-600 font-semibold uppercase">Ngồi</div>
                  </div>
                </div>
                <div className="text-xs text-slate-500 pt-1 border-t border-slate-100 flex items-center justify-between">
                  <span>Tổng số bàn</span>
                  <span className="font-bold text-slate-800">{zoneStats[selectedZoneObj.id]?.total || 0}</span>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Right: Zone floor plan */}
        <div className="col-span-12 lg:col-span-8 xl:col-span-9">
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            {/* Zone header */}
            <div className="px-5 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/60">
              <div className="flex items-center gap-2">
                {selectedZoneObj && (
                  <span
                    className="w-3 h-3 rounded-full"
                    style={{ backgroundColor: selectedZoneObj.color }}
                  />
                )}
                <h3 className="text-sm font-bold text-slate-700">
                  {selectedZoneObj?.name || 'Khu vực'}
                </h3>
                <span className="text-xs text-slate-400">({zoneTables.length} bàn)</span>
              </div>
              <div className="text-xs text-slate-500">
                {formatDate(selectedDate)}
              </div>
            </div>

            {/* Floor plan canvas */}
            <div className="relative bg-gradient-to-br from-slate-50 to-slate-100 p-6 min-h-[500px]">
              <div className="absolute top-3 left-3 text-[10px] text-slate-400 font-semibold uppercase tracking-wider">
                Khu vực chờ
              </div>
              <div className="absolute top-3 right-3 text-[10px] text-slate-400 font-semibold uppercase tracking-wider">
                Lễ tân
              </div>

              {zoneTables.length === 0 ? (
                <div className="flex flex-col items-center justify-center h-[400px] text-slate-400">
                  <Layers size={32} className="mb-2 opacity-50" />
                  <div className="text-sm">Khu vực này chưa có bàn nào</div>
                </div>
              ) : (
                <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4 mt-6">
                  {zoneTables.map(t => {
                    const s = tableStatusStyle[t.status];
                    const r = reservationByTable.get(t.code);
                    return (
                      <div
                        key={t.id}
                        className={`${s.bg} ${s.border} border-2 rounded-2xl p-3 flex flex-col items-center justify-center min-h-[120px] transition-all hover:shadow-lg cursor-pointer hover:scale-105`}
                      >
                        <div className={`text-2xl font-black ${s.text}`}>{t.code}</div>
                        <div className="flex items-center gap-1 text-[10px] text-slate-500 mt-1">
                          <Users size={10} /> {t.capacity} chỗ
                        </div>
                        <span className={`mt-1.5 px-2 py-0.5 rounded-full text-[9px] font-bold ${s.badge}`}>
                          {s.label}
                        </span>
                        {r && (
                          <div className="mt-2 text-[11px] text-slate-800 font-bold truncate w-full text-center">
                            {r.customerName}
                          </div>
                        )}
                        {r && (
                          <div className="flex items-center gap-1 text-[10px] text-slate-500 mt-0.5">
                            <Clock size={9} /> {r.time}
                          </div>
                        )}
                        {r && (
                          <div className="flex items-center gap-1 text-[10px] text-slate-500">
                            <Users size={9} /> {r.guests} khách
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
