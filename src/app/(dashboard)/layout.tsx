import { LayoutDashboard, List, Map, Utensils, Settings, LogOut, ChevronDown, Bell, Search, User } from "lucide-react";
import Link from "next/link";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex h-screen overflow-hidden bg-slate-50">
      {/* Sidebar */}
      <aside className="w-60 border-r border-slate-200 bg-white shadow-sm flex flex-col shrink-0">
        <div className="p-5 border-b border-slate-100">
          <div className="flex items-center gap-2">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-blue-600 to-indigo-600 flex items-center justify-center text-white font-black text-sm shadow-md shadow-blue-500/20">
              NC
            </div>
            <div>
              <h1 className="text-sm font-black text-slate-900 tracking-tight">NGƯU CÁT</h1>
              <p className="text-[10px] text-slate-400 font-semibold uppercase tracking-wider">Booking Manager</p>
            </div>
          </div>
        </div>

        <nav className="flex-1 px-3 space-y-1 py-4">
          <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider px-3 mb-1">Vận hành</div>
          <Link href="/" className="flex items-center gap-3 px-3 py-2 text-slate-700 rounded-lg hover:bg-slate-100 transition-colors text-sm font-medium">
            <LayoutDashboard size={16} />
            <span>Lịch đặt bàn</span>
          </Link>
          <Link href="/list" className="flex items-center gap-3 px-3 py-2 text-slate-700 rounded-lg hover:bg-slate-100 transition-colors text-sm font-medium">
            <List size={16} />
            <span>Danh sách</span>
          </Link>
          <Link href="/floor-plan" className="flex items-center gap-3 px-3 py-2 text-slate-700 rounded-lg hover:bg-slate-100 transition-colors text-sm font-medium">
            <Map size={16} />
            <span>Sơ đồ bàn</span>
          </Link>

          <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider px-3 mb-1 mt-5">Phục vụ</div>
          <Link href="/order/SF_00001729" className="flex items-center gap-3 px-3 py-2 text-slate-700 rounded-lg hover:bg-slate-100 transition-colors text-sm font-medium">
            <Utensils size={16} />
            <span>Chọn món</span>
          </Link>

          <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider px-3 mb-1 mt-5">Hệ thống</div>
          <button className="w-full flex items-center gap-3 px-3 py-2 text-slate-600 rounded-lg hover:bg-slate-100 transition-colors text-sm font-medium">
            <Settings size={16} />
            <span>Cấu hình</span>
          </button>
        </nav>

        <div className="p-3 border-t border-slate-100 space-y-1">
          <div className="flex items-center gap-2.5 px-3 py-2 rounded-lg bg-slate-50">
            <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-indigo-500 flex items-center justify-center text-white text-xs font-bold">
              NA
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-xs font-bold text-slate-800 truncate">Nguyễn Văn A</div>
              <div className="text-[10px] text-slate-500">Quản lý ca</div>
            </div>
            <button className="p-1 rounded hover:bg-white text-slate-400">
              <LogOut size={13} />
            </button>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col overflow-hidden">
        {/* Header */}
        <header className="h-16 border-b border-slate-200 bg-white flex items-center justify-between px-6 shrink-0">
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2 px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-sm">
              <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              <span className="font-semibold text-slate-700">Chi nhánh: Ngưu Cát Quận 1</span>
              <ChevronDown size={14} className="text-slate-400" />
            </div>
          </div>

          <div className="flex items-center gap-2">
            <div className="relative">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                type="text"
                placeholder="Tìm nhanh..."
                className="pl-9 pr-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-sm w-56 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
              />
            </div>
            <button className="relative p-2 rounded-lg hover:bg-slate-100 text-slate-600">
              <Bell size={16} />
              <span className="absolute top-1 right-1 w-2 h-2 rounded-full bg-rose-500" />
            </button>
            <div className="w-px h-6 bg-slate-200" />
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-indigo-500 flex items-center justify-center text-white text-xs font-bold">
                NA
              </div>
              <ChevronDown size={14} className="text-slate-400" />
            </div>
          </div>
        </header>

        {/* Scrollable Content */}
        <section className="flex-1 overflow-auto p-6">
          {children}
        </section>
      </main>
    </div>
  );
}
