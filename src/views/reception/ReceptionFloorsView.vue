<template>
  <div
    class="h-full flex flex-col gap-1.5 select-none bg-gray-50/50 overflow-hidden text-gray-800 font-sans"
  >
    <!-- Title & Status Legend Row -->
    <div
      class="flex flex-col md:flex-row md:items-center justify-between gap-2 border-b border-gray-200/80 pb-1.5 shrink-0"
    >
      <div>
        <h1
          class="text-lg font-black text-gray-900 tracking-tight flex items-center gap-2"
        >
          <span>🖥️</span>
          {{ t('admin_floors.title') }}
        </h1>
        <p class="text-[10px] text-gray-500 font-medium mt-0">
          {{ t('admin_floors.subtitle') }}
        </p>
      </div>

      <!-- Compact Status Legend -->
      <div
        class="flex items-center gap-1.5 text-[9px] font-black uppercase tracking-wider"
      >
        <div
          class="flex items-center gap-1 bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded-lg border border-emerald-100/50"
        >
          <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
          {{ t('admin_floors.status.empty') }}
        </div>
        <div
          class="flex items-center gap-1 bg-amber-50 text-amber-700 px-2 py-0.5 rounded-lg border border-amber-100/50"
        >
          <span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
          {{ t('admin_floors.status.reserved') }}
        </div>
        <div
          class="flex items-center gap-1 bg-blue-50 text-blue-700 px-2 py-0.5 rounded-lg border border-blue-100/50"
        >
          <span class="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
          {{ t('admin_floors.status.arrived') }}
        </div>
        <div
          class="flex items-center gap-1 bg-rose-50 text-rose-700 px-2 py-0.5 rounded-lg border border-rose-100/50"
        >
          <span class="w-1.5 h-1.5 rounded-full bg-rose-500"></span>
          {{ t('admin_floors.status.serving') }}
        </div>
      </div>
    </div>

    <!-- Timeline Slider -->
    <div
      class="bg-white border border-gray-200 rounded-xl p-2 shadow-sm shrink-0 flex flex-col md:flex-row md:items-center justify-between gap-2"
    >
      <div class="flex items-center gap-3 select-none">
        <div
          class="w-9 h-9 rounded-xl bg-orange-50 flex items-center justify-center text-lg"
        >
          🕒
        </div>
        <div>
          <h2 class="text-xs font-black text-gray-800 uppercase tracking-wide">
            {{ t('reception_floors.timeline_label') }}
          </h2>
          <p class="text-[10px] text-gray-400 font-semibold mt-0.5">
            {{ t('admin_floors.simulation.subtitle') }}
          </p>
        </div>
      </div>

      <div
        class="flex-1 flex items-center gap-4 bg-gray-50 border border-gray-150 px-4 py-2 rounded-xl"
      >
        <input
          type="time"
          v-model="inputTimelineTime"
          class="text-xs font-black text-orange-600 bg-orange-50 border border-orange-200 px-2 py-1 rounded-lg shrink-0 focus:outline-none focus:ring-1 focus:ring-[#FF7B89] cursor-pointer"
        />
        <div class="flex-1 flex items-center gap-2">
          <span class="text-[9px] text-gray-400 font-bold select-none">11:00</span>
          <input
            type="range"
            min="660"
            max="1320"
            step="30"
            v-model.number="timelineTimeRaw"
            @change="commitTimelineTime"
            @input="checkConflicts"
            class="flex-1 accent-[#FF7B89] h-1.5 bg-gray-200 rounded-lg cursor-pointer"
          />
          <span class="text-[9px] text-gray-400 font-bold select-none">22:00</span>
        </div>
        <span class="text-sm font-black text-[#FF7B89] w-12 text-center">{{
          formatTime(timelineTime)
        }}</span>
        <button
          @click="resetTimeline"
          class="text-[10px] text-gray-500 hover:text-[#FF7B89] underline shrink-0"
        >
          {{ t('reception_floors.reset') }}
        </button>
      </div>
    </div>

    <!-- Zone Navigation Bar -->
    <div
      class="bg-white border border-gray-200 rounded-xl p-1.5 shadow-sm shrink-0 flex items-center gap-2"
    >
      <div class="relative shrink-0 z-50">
        <button
          @click="isZoneDropdownOpen = !isZoneDropdownOpen"
          class="px-3 py-1.5 bg-white border border-gray-200 rounded-lg text-xs font-black text-gray-700 hover:bg-gray-50 flex items-center gap-1.5 shadow-sm active:scale-95"
        >
          <span>{{ t('admin_floors.zone.select') }}</span>
          <span class="text-gray-400 text-[10px]">▼</span>
        </button>
        <div
          v-if="isZoneDropdownOpen"
          class="fixed inset-0 z-40"
          @click="isZoneDropdownOpen = false"
        ></div>
        <div
          v-if="isZoneDropdownOpen"
          class="absolute left-0 mt-1.5 w-56 bg-white border border-gray-200 rounded-xl shadow-xl py-1.5 z-50 animate-fade-in max-h-64 overflow-y-auto"
        >
          <button
            v-for="zone in zoneOptions"
            :key="zone.value"
            @click="selectedZone = zone.value; isZoneDropdownOpen = false"
            :class="[
              'w-full text-left px-4 py-2 text-xs font-bold transition-colors flex items-center justify-between',
              selectedZone === zone.value
                ? 'bg-pink-50 text-[#FF7B89]'
                : 'text-gray-600 hover:bg-gray-50',
            ]"
          >
            <span>{{ zone.label }}</span>
            <span class="text-[9px] bg-gray-100 text-gray-500 px-1.5 py-0.5 rounded-full font-bold">
              {{ getZoneTableCount(zone.value) }}
            </span>
          </button>
        </div>
      </div>

      <div class="h-6 w-px bg-gray-200 shrink-0"></div>

      <div class="flex items-center gap-2 select-none">
        <span class="text-[10px] font-bold text-gray-400 uppercase tracking-wider">
          {{ t('admin_floors.zone.viewing') }}
        </span>
        <div
          class="bg-pink-50 border border-pink-100 text-[#FF7B89] px-2.5 py-1 rounded-lg text-xs font-black flex items-center gap-2 shadow-sm"
        >
          <span>📍 {{ selectedZoneLabel }}</span>
          <span class="text-[9px] bg-[#FF7B89] text-white px-1.5 py-0.5 rounded-full font-black">
            {{ getZoneTableCount(selectedZone) }} bàn
          </span>
        </div>
      </div>
    </div>

    <!-- Main 3-Column Layout -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-2 flex-1 min-h-0 overflow-hidden">
      <!-- LEFT COLUMN: Waiting Reservations (Draggable) -->
      <div class="lg:col-span-3 flex flex-col min-h-0 overflow-hidden">
        <div
          class="bg-white border border-gray-200 rounded-xl shadow-sm flex-1 flex flex-col overflow-hidden min-h-0"
        >
          <div class="p-2.5 border-b border-gray-100 bg-orange-50 shrink-0">
            <h2 class="text-xs font-black text-gray-800 flex items-center gap-2">
              ⏳ {{ t('reception_floors.waiting_title') }}
              <span class="bg-orange-500 text-white text-[9px] px-2 py-0.5 rounded-full">
                {{ unassignedReservations.length }}
              </span>
            </h2>
          </div>
          <div class="flex-1 overflow-y-auto p-2.5 space-y-2 custom-scrollbar min-h-0">
            <div
              v-for="res in unassignedReservations"
              :key="res.id"
              draggable="true"
              @dragstart="handleDragStart($event, res)"
              @dragend="handleDragEnd"
              class="reservation-card bg-white border-2 border-gray-200 rounded-xl p-2.5 cursor-grab active:cursor-grabbing hover:border-orange-400 hover:shadow-md transition-all group"
            >
              <div class="flex items-start gap-2.5">
                <div
                  class="w-9 h-9 rounded-full bg-orange-100 text-orange-600 flex items-center justify-center font-bold text-sm shrink-0"
                >
                  {{ res.customerName.charAt(0).toUpperCase() }}
                </div>
                <div class="flex-1 min-w-0">
                  <p class="font-semibold text-gray-900 text-xs truncate">{{ res.customerName }}</p>
                  <div class="flex items-center gap-2 text-[10px] text-gray-500 mt-0.5">
                    <span>🕐 {{ res.reservationTime }}</span>
                    <span>👥 {{ res.adults + res.children }} {{ t('admin_floors.reservation.guests') }}</span>
                  </div>
                </div>
              </div>
              <div class="mt-1.5 pt-1.5 border-t border-gray-100 flex items-center justify-between">
                <span class="text-[9px] text-gray-400">{{ t('reception_floors.drag_hint') }}</span>
                <span class="opacity-0 group-hover:opacity-100 text-orange-500 text-[9px] font-medium transition-opacity">
                  {{ t('reception_floors.drag_handle') }}
                </span>
              </div>
            </div>

            <div v-if="unassignedReservations.length === 0" class="text-center py-8 text-gray-400">
              <p class="text-xs">{{ t('reception_floors.all_assigned') }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- CENTER COLUMN: Table Map (Droppable) -->
      <div class="lg:col-span-6 flex flex-col min-h-0 overflow-hidden">
        <div
          class="bg-white border border-gray-200 rounded-xl p-2.5 shadow-sm flex-1 flex flex-col overflow-hidden min-h-0"
        >
          <div class="flex justify-between items-center mb-2 border-b border-gray-100 pb-1.5 shrink-0">
            <h2 class="text-sm font-black text-gray-800 uppercase tracking-wider flex items-center gap-1.5">
              {{ t('admin_floors.map.title') }}
              <span class="text-[#FF7B89] font-black text-sm">{{ selectedZoneLabel }}</span>
            </h2>
          </div>

          <div class="space-y-3 flex-1 overflow-y-auto pr-1 custom-scrollbar min-h-0">
            <div v-for="area in filteredAreas" :key="area.name" class="flex flex-col gap-2">
              <div v-if="selectedZone === 'All'" class="flex items-center gap-1.5 mt-1">
                <span class="w-1.5 h-3 bg-[#FF7B89] rounded-full"></span>
                <h3 class="text-[11px] font-black text-gray-500 uppercase tracking-wider">
                  {{ area.name }} ({{ area.description }})
                </h3>
              </div>

              <div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-2">
                <div
                  v-for="table in area.tables"
                  :key="table.code"
                  :data-table-id="table.id || table.code"
                  @click="openTableModal(area.name, table)"
                  @dragover.prevent="handleDragOver($event, table)"
                  @dragenter="handleDragEnter($event, table)"
                  @dragleave="handleDragLeave($event, table)"
                  @drop="handleDrop($event, table)"
                  :class="[
                    'relative p-1.5 rounded-lg border-2 transition-all duration-150 cursor-pointer shadow-sm flex flex-col justify-between h-[80px] hover:-translate-y-0.5 hover:shadow-md select-none',
                    getTableColorClass(table),
                    isDragOverTable === (table.id || table.code) ? 'ring-4 ring-orange-400 scale-105 z-10' : '',
                    isInvalidDropTable === (table.id || table.code) ? 'animate-shake border-red-500 bg-red-50' : '',
                  ]"
                >
                  <div class="flex justify-between items-start gap-1">
                    <span class="font-black text-sm text-gray-900 leading-none">{{ table.code }}</span>
                    <span
                      :class="[
                        'text-[8px] font-black uppercase px-1.5 py-0.5 rounded leading-none border',
                        getBadgeColorClass(table.status),
                      ]"
                    >
                      {{ translateTableStatus(table.status) }}
                    </span>
                  </div>

                  <div class="flex-1 flex flex-col justify-center mt-1 leading-tight">
                    <template v-if="table.status === 'Available'">
                      <span class="text-[9px] text-emerald-600 font-extrabold">
                        {{ t('admin_floors.table.ready') }}
                      </span>
                      <span class="text-[9px] text-gray-400 font-medium mt-0.5">
                        {{ t('admin_floors.table.capacity') }} {{ table.capacity }} {{ t('admin_floors.table.seats') }}
                      </span>
                    </template>

                    <template v-else-if="table.status === 'Reserved'">
                      <div class="text-[10px] font-black text-gray-800 truncate">
                        👤 {{ table.customerName || t('admin_floors.reservation.guest') }}
                      </div>
                      <div class="flex items-center justify-between text-[9px] text-gray-400 font-bold mt-1">
                        <span>👥 {{ table.capacity }} {{ t('admin_floors.reservation.guests') }}</span>
                        <span class="text-amber-600 font-extrabold">🕒 {{ getTableReservationTime(table.code) || '—' }}</span>
                      </div>
                    </template>

                    <template v-else-if="table.status === 'Arrived'">
                      <div class="text-[10px] font-black text-blue-800 truncate">
                        👤 {{ table.customerName || 'Khách check-in' }}
                      </div>
                      <div class="text-[9px] text-blue-500 font-bold mt-1">
                        🚶 {{ t('admin_floors.status.arrived') }}: {{ getTableArrivalTime(table.code) || '—' }}
                      </div>
                    </template>

                    <template v-else-if="table.status === 'Serving'">
                      <div class="text-[10px] font-black text-gray-800 truncate">
                        👤 {{ table.customerName || t('admin_floors.table.walk_in') }}
                      </div>
                      <div class="flex items-center justify-between text-[9px] mt-1 font-extrabold">
                        <span class="text-rose-600 font-black bg-rose-50 px-1 rounded border border-rose-100/50">
                          💰 {{ table.billAmount || '0đ' }}
                        </span>
                        <span class="text-gray-400 font-bold text-[8px]">🕒 {{ table.checkInTime || '—' }}</span>
                      </div>
                    </template>

                    <template v-else-if="table.status === 'Maintenance'">
                      <span class="text-[9px] text-gray-500 font-extrabold">
                        {{ t('admin_floors.table.maintenance') }}
                      </span>
                    </template>
                  </div>

                  <!-- Conflict Badge -->
                  <div
                    v-if="conflictTables.has(table.code)"
                    class="absolute -top-2 -right-2 bg-red-500 text-white text-[8px] font-bold px-1.5 py-0.5 rounded-full shadow-lg animate-pulse"
                  >
                    {{ t('reception_floors.conflict_badge') }}
                  </div>

                  <!-- Drop Indicator -->
                  <div
                    v-if="isDragOverTable === (table.id || table.code) && table.status === 'Available' && !conflictTables.has(table.code)"
                    class="absolute inset-0 bg-green-500/10 rounded-lg flex items-center justify-center pointer-events-none"
                  >
                    <span class="bg-green-600 text-white px-2 py-0.5 rounded-full text-[9px] font-bold shadow-lg">
                      {{ t('reception_floors.drop_here') }}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div v-if="filteredAreas.length === 0" class="py-12 text-center text-gray-400 font-medium text-xs">
              {{ t('admin_floors.map.no_tables') }}
            </div>
          </div>
        </div>
      </div>

      <!-- RIGHT COLUMN: Calendar + Zone Summary -->
      <div class="lg:col-span-3 flex flex-col gap-1.5 min-h-0 overflow-hidden">
        <div
          class="bg-white border border-gray-200 rounded-xl p-2.5 shadow-sm flex-1 flex flex-col overflow-hidden min-h-0"
        >
          <!-- Calendar -->
          <div class="flex justify-between items-center mb-1.5 pb-1 border-b border-gray-100 shrink-0">
            <h3 class="text-xs font-black text-gray-800 uppercase tracking-wider flex items-center gap-1">
              {{ t('admin_floors.schedule.title') }}
            </h3>
          </div>

          <div class="bg-gray-50 border border-gray-150 rounded-lg p-1.5 shadow-inner shrink-0">
            <div class="flex justify-between items-center mb-2">
              <button @click="prevMonth" class="p-0.5 rounded hover:bg-gray-200 text-gray-600 transition-colors">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
                </svg>
              </button>
              <span class="text-[10px] font-black text-gray-800 tracking-tight">{{ monthNames[currentMonth] }} {{ currentYear }}</span>
              <button @click="nextMonth" class="p-0.5 rounded hover:bg-gray-200 text-gray-600 transition-colors">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
                </svg>
              </button>
            </div>

            <div class="grid grid-cols-7 gap-0.5 text-[8px] font-extrabold text-gray-400 text-center uppercase tracking-wider mb-1">
              <span>T2</span><span>T3</span><span>T4</span><span>T5</span><span>T6</span><span>T7</span><span class="text-red-500">CN</span>
            </div>

            <div class="grid grid-cols-7 gap-0.5 text-[9px] text-center font-bold">
              <button
                v-for="d in calendarDays"
                :key="`${d.year}-${d.month}-${d.day}`"
                @click="selectCalendarDay(d)"
                :class="[
                  'py-0.5 rounded transition-all focus:outline-none flex items-center justify-center h-5 w-full',
                  d.isCurrentMonth ? 'text-gray-700' : 'text-gray-300 font-normal',
                  isSameDate(selectedDate, d.year, d.month, d.day)
                    ? 'bg-[#FF7B89] text-white shadow-sm font-black scale-105'
                    : 'hover:bg-white hover:text-[#FF7B89]',
                ]"
              >
                {{ d.day }}
              </button>
            </div>

            <div class="text-center text-[9px] font-extrabold text-[#FF7B89] mt-1 border-t border-gray-200/50 pt-1 select-none uppercase tracking-wide">
              {{ selectedDateLabelFormatted }}
            </div>
          </div>

          <!-- Shift Tabs -->
          <div class="flex gap-1 overflow-x-auto p-0.5 bg-gray-50 border border-gray-150 rounded-lg text-[9px] font-black tracking-wide mt-2 mb-2 shrink-0 scrollbar-none">
            <button
              @click="activeShift = 'all'"
              :class="['flex-1 py-1 rounded transition-colors whitespace-nowrap', activeShift === 'all' ? 'bg-white shadow text-[#FF7B89]' : 'text-gray-500 hover:text-[#FF7B89]']"
            >
              {{ t('admin_floors.filter.all') }} ({{ getShiftCount('all') }})
            </button>
            <button
              @click="activeShift = 'morning'"
              :class="['flex-1 py-1 rounded transition-colors whitespace-nowrap', activeShift === 'morning' ? 'bg-white shadow text-[#FF7B89]' : 'text-gray-500 hover:text-[#FF7B89]']"
            >
              Sáng ({{ getShiftCount('morning') }})
            </button>
            <button
              @click="activeShift = 'lunch'"
              :class="['flex-1 py-1 rounded transition-colors whitespace-nowrap', activeShift === 'lunch' ? 'bg-white shadow text-[#FF7B89]' : 'text-gray-500 hover:text-[#FF7B89]']"
            >
              Trưa ({{ getShiftCount('lunch') }})
            </button>
            <button
              @click="activeShift = 'evening'"
              :class="['flex-1 py-1 rounded transition-colors whitespace-nowrap', activeShift === 'evening' ? 'bg-white shadow text-[#FF7B89]' : 'text-gray-500 hover:text-[#FF7B89]']"
            >
              Tối ({{ getShiftCount('evening') }})
            </button>
          </div>

          <!-- Zone Summary -->
          <div class="flex-1 overflow-y-auto min-h-0 custom-scrollbar">
            <h3 class="text-[9px] font-black text-gray-400 uppercase tracking-wider mb-1.5">
              {{ t('reception_floors.zone_summary') }}
            </h3>
            <div class="space-y-1.5">
              <div
                v-for="zone in zoneSummary"
                :key="zone.value"
                @click="selectedZone = zone.value"
                :class="[
                  'flex items-center justify-between p-2 rounded-lg border transition-all cursor-pointer',
                  selectedZone === zone.value
                    ? 'bg-[#FF7B89]/5 border-[#FF7B89] ring-1 ring-[#FF7B89]'
                    : 'bg-gray-50 border-gray-100 hover:border-orange-200',
                ]"
              >
                <div>
                  <p class="font-semibold text-[11px] text-gray-800 truncate">{{ zone.label }}</p>
                  <p class="text-[9px] text-gray-500">{{ zone.serving }} ăn • {{ zone.reserved }} đặt</p>
                </div>
                <div class="text-right">
                  <p class="font-bold text-[11px] text-[#FF7B89]">{{ zone.revenue }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Footer Action Bar -->
    <div
      class="bg-white border-t border-gray-200 py-1.5 px-3 grid grid-cols-1 md:grid-cols-3 items-center gap-2 z-40 shadow-sm shrink-0"
    >
      <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-[9px] font-black border-r border-gray-150 pr-2 select-none">
        <div class="flex items-center gap-1 text-gray-500">
          {{ t('admin_floors.system.title') }}
          <span class="bg-gray-100 border border-gray-150 px-2 py-0.5 rounded text-gray-700 font-mono tracking-wider">{{ currentTime }}</span>
        </div>
        <div class="flex items-center gap-2">
          <span>{{ t('admin_floors.system.tables') }}</span>
          <span class="text-emerald-600 bg-emerald-50 border border-emerald-100 px-1.5 py-0.5 rounded">{{ stats.availableTables }}/{{ stats.totalTables }} {{ t('admin_floors.table.empty') }}</span>
        </div>
        <div class="flex items-center gap-2">
          <span>{{ t('admin_floors.table.seats_total') }}</span>
          <span class="text-blue-600 bg-blue-50 border border-blue-100 px-1.5 py-0.5 rounded">{{ stats.availableSeats }}/{{ stats.totalSeats }} {{ t('admin_floors.table.empty') }}</span>
        </div>
      </div>

      <div class="flex flex-wrap items-center justify-center gap-x-3 gap-y-1 text-[9px] font-black border-r border-gray-150 px-2 select-none">
        <div class="flex items-center gap-1.5">
          <span>{{ t('admin_floors.today.bookings') }}</span>
          <span class="bg-gray-100 px-2 py-0.5 rounded border border-gray-200 text-gray-700 text-xs">{{ sidebarStats.total }}</span>
        </div>
        <div class="flex items-center gap-1.5">
          <span class="text-blue-600">{{ t('admin_floors.today.check_in') }}</span>
          <span class="bg-blue-50 text-blue-700 px-2 py-0.5 rounded border border-blue-200 text-xs">{{ sidebarStats.arrived }}</span>
        </div>
        <div class="flex items-center gap-1.5">
          <span class="text-amber-600">{{ t('admin_floors.today.waiting') }}</span>
          <span class="bg-amber-50 text-amber-700 px-2 py-0.5 rounded border border-amber-200 text-xs">{{ sidebarStats.waiting }}</span>
        </div>
      </div>

      <div class="flex gap-1.5 justify-end w-full">
        <button
          @click="resetToCurrentState"
          class="text-center py-1.5 px-2.5 rounded-lg border border-gray-250 bg-white hover:bg-gray-50 text-gray-700 font-extrabold text-[10px] transition-colors shadow-sm select-none flex items-center justify-center gap-1 active:scale-95"
        >
          {{ t('admin_floors.current.time') }}
        </button>
        <button
          @click="openQuickArrivedModal"
          class="bg-blue-600 hover:bg-blue-700 text-white font-black text-[10px] py-1.5 px-2.5 rounded-lg transition-all shadow-sm flex items-center justify-center gap-1 active:scale-95"
        >
          {{ t('admin_floors.quick_action.welcome') }}
        </button>
        <button
          @click="openQuickOpenModal"
          class="bg-rose-600 hover:bg-rose-700 text-white font-black text-[10px] py-1.5 px-2.5 rounded-lg transition-all shadow-sm flex items-center justify-center gap-1 active:scale-95"
        >
          {{ t('admin_floors.quick_action.open_fast') }}
        </button>
        <button
          @click="openCreateBookingModal"
          class="bg-[#FF7B89] hover:bg-[#FF5A6E] text-white font-black text-[10px] py-1.5 px-2.5 rounded-lg transition-all shadow-sm flex items-center justify-center gap-1 active:scale-95"
        >
          {{ t('admin_floors.quick_action.book') }}
        </button>
      </div>
    </div>

    <!-- MODAL 1: TABLE DETAILS -->
    <div v-if="isTableModalOpen && selectedTableForModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm" @click="closeTableModal"></div>
      <div class="bg-white border-2 border-pink-100 rounded-3xl w-full max-w-md shadow-2xl p-6 z-10 relative animate-fade-in text-xs font-bold text-gray-700">
        <button @click="closeTableModal" class="absolute top-4 right-4 w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 hover:text-gray-800 flex items-center justify-center transition-colors font-bold text-sm select-none">✕</button>

        <div class="flex items-center gap-3 mb-5 border-b border-gray-100 pb-3 select-none">
          <div class="w-12 h-12 rounded-2xl bg-pink-50 flex items-center justify-center text-2xl">🪑</div>
          <div>
            <h3 class="text-lg font-black text-gray-900 tracking-tight">{{ t('admin_floors.modal.table_details') }} {{ selectedTableForModal.code }}</h3>
            <p class="text-[10px] text-gray-400 font-bold uppercase">{{ t('admin_floors.modal.zone') }}: {{ selectedTableForModal.areaName }}</p>
          </div>
        </div>

        <div class="space-y-4 mb-5">
          <div class="grid grid-cols-2 gap-4 select-none">
            <div class="bg-gray-50 p-3 rounded-xl border border-gray-100">
              <span class="block text-[9px] font-black text-gray-400 uppercase tracking-wider mb-0.5">{{ t('admin_floors.modal.capacity') }}</span>
              <span class="font-extrabold text-xs text-gray-800">{{ selectedTableForModal.capacity }}</span>
            </div>
            <div class="bg-gray-50 p-3 rounded-xl border border-gray-100">
              <span class="block text-[9px] font-black text-gray-400 uppercase tracking-wider mb-0.5">{{ t('admin_floors.modal.status') }}</span>
              <span :class="['inline-block text-[8px] font-black uppercase px-2 py-0.5 rounded border mt-0.5 tracking-wide', getBadgeColorClass(selectedTableForModal.status)]">
                {{ translateTableStatus(selectedTableForModal.status) }}
              </span>
            </div>
          </div>

          <div class="bg-gray-50 p-3.5 rounded-xl border border-gray-100 space-y-2.5">
            <h4 class="text-[10px] font-black text-gray-400 uppercase">{{ t('admin_floors.modal.serving_info') }}</h4>
            <div class="space-y-1">
              <label class="text-[8px] font-black text-gray-400 uppercase">{{ t('admin_floors.modal.customer_name') }}</label>
              <input
                type="text"
                v-model="tableModalForm.customerName"
                :placeholder="i18n.t('admin_floors.placeholder.customer_name')"
                class="w-full bg-white border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
              />
            </div>
            <div class="grid grid-cols-2 gap-3.5">
              <div class="space-y-1">
                <label class="text-[8px] font-black text-gray-400 uppercase">{{ t('admin_floors.modal.bill_estimate') }}</label>
                <div class="w-full bg-rose-50 border border-rose-200 rounded-lg px-2.5 py-2 font-extrabold text-rose-700 text-sm">{{ liveBillTotal }}</div>
              </div>
              <div class="space-y-1">
                <label class="text-[8px] font-black text-gray-400 uppercase">{{ t('admin_floors.modal.time_in') }}</label>
                <div class="w-full bg-rose-50 border border-rose-200 rounded-lg px-2.5 py-2 font-extrabold text-rose-700 text-sm">{{ liveOccupiedDuration }}</div>
              </div>
            </div>
          </div>
        </div>

        <div class="space-y-3">
          <span class="block text-[9px] font-black text-gray-400 uppercase tracking-wider mb-2 select-none">{{ t('admin_floors.modal.change_status') }}</span>
          <div class="grid grid-cols-2 gap-2 select-none">
            <button
              @click="setTableModalStatus('Available')"
              :class="['py-2 px-3 rounded-xl border text-[10px] font-black transition-all', tableModalForm.status === 'Available' ? 'bg-emerald-500 border-emerald-600 text-white shadow-sm' : 'bg-emerald-50 text-emerald-800 border-emerald-100 hover:bg-emerald-100']"
            >{{ t('admin_floors.status.set_empty') }}</button>
            <button
              @click="setTableModalStatus('Reserved')"
              :class="['py-2 px-3 rounded-xl border text-[10px] font-black transition-all', tableModalForm.status === 'Reserved' ? 'bg-amber-500 border-amber-600 text-white shadow-sm' : 'bg-amber-50 text-amber-800 border-amber-100 hover:bg-amber-100']"
            >{{ t('admin_floors.status.set_reserved') }}</button>
            <button
              @click="setTableModalStatus('Arrived')"
              :class="['py-2 px-3 rounded-xl border text-[10px] font-black transition-all', tableModalForm.status === 'Arrived' ? 'bg-blue-600 border-blue-700 text-white shadow-sm' : 'bg-blue-50 text-blue-800 border-blue-100 hover:bg-blue-100']"
            >{{ t('admin_floors.status.check_in') }}</button>
            <button
              @click="setTableModalStatus('Serving')"
              :class="['py-2 px-3 rounded-xl border text-[10px] font-black transition-all', tableModalForm.status === 'Serving' ? 'bg-rose-600 border-rose-700 text-white shadow-sm' : 'bg-rose-50 text-rose-800 border-rose-100 hover:bg-rose-100']"
            >{{ t('admin_floors.status.open_serving') }}</button>
          </div>

          <div class="flex gap-2 pt-3.5 border-t border-gray-100 mt-4">
            <button @click="closeTableModal" class="flex-1 py-2 rounded-xl border border-gray-250 bg-white hover:bg-gray-50 text-gray-700 text-[11px] font-bold transition-colors select-none">{{ t('admin_floors.action.close') }}</button>
            <button @click="goToOrderScreen(selectedTableForModal.code)" class="flex-1 py-2 rounded-xl bg-amber-500 hover:bg-amber-600 text-white text-[11px] font-black transition-colors shadow-sm select-none">🍽️ {{ t('sidebar.order_menu') }}</button>
            <button @click="saveTableModal" class="flex-1 py-2 rounded-xl bg-[#FF7B89] hover:bg-[#FF5A6E] text-white text-[11px] font-black transition-colors shadow-sm select-none">{{ t('admin_floors.action.save') }}</button>
          </div>
        </div>
      </div>
    </div>

    <!-- MODAL 2: CREATE BOOKING -->
    <div v-if="isCreateBookingModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm" @click="isCreateBookingModalOpen = false"></div>
      <div class="bg-white border-2 border-pink-100 rounded-3xl w-full max-w-lg shadow-2xl p-6 z-10 relative animate-fade-in text-xs font-bold text-gray-700 max-h-[90vh] overflow-y-auto">
        <button @click="isCreateBookingModalOpen = false" class="absolute top-4 right-4 w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 hover:text-gray-800 flex items-center justify-center transition-colors font-bold text-sm select-none z-10">✕</button>

        <div class="flex items-center gap-3 mb-5 border-b border-gray-100 pb-3 select-none">
          <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-pink-500 to-red-500 flex items-center justify-center text-lg shadow-sm">📅</div>
          <div>
            <h3 class="text-lg font-black text-gray-900 tracking-tight">{{ t('admin_floors.action.book') }}</h3>
            <p class="text-[10px] text-gray-400 font-semibold">Nhập thông tin khách hàng và yêu cầu đặt bàn</p>
          </div>
        </div>

        <div class="space-y-4 mb-5">
          <div class="space-y-1">
            <label class="text-[9px] font-black text-gray-400 uppercase">{{ t('admin_floors.booking.customer_name') }} <span class="text-red-500">*</span></label>
            <input
              type="text"
              v-model="newBookingForm.customerName"
              :placeholder="i18n.t('admin_floors.placeholder.booking_name')"
              class="w-full bg-gray-50 border rounded-lg px-3 py-2.5 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89] transition-colors"
              :class="bookingErrors.customerName ? 'border-red-400' : 'border-gray-200'"
            />
            <p v-if="bookingErrors.customerName" class="text-[10px] text-red-500 font-semibold">{{ bookingErrors.customerName }}</p>
          </div>

          <div class="grid grid-cols-2 gap-3.5">
            <div class="space-y-1">
              <label class="text-[9px] font-black text-gray-400 uppercase">{{ t('admin_floors.booking.phone') }} <span class="text-red-500">*</span></label>
              <input
                type="tel"
                v-model="newBookingForm.phone"
                :placeholder="i18n.t('admin_floors.placeholder.phone')"
                class="w-full bg-gray-50 border rounded-lg px-3 py-2.5 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89] transition-colors"
                :class="bookingErrors.phone ? 'border-red-400' : 'border-gray-200'"
              />
              <p v-if="bookingErrors.phone" class="text-[10px] text-red-500 font-semibold">{{ bookingErrors.phone }}</p>
            </div>
            <div class="space-y-1">
              <label class="text-[9px] font-black text-gray-400 uppercase">{{ t('admin_floors.booking.time') }} <span class="text-red-500">*</span></label>
              <div class="flex gap-1.5">
                <input
                  type="time"
                  v-model="newBookingForm.reservationTime"
                  class="flex-1 bg-gray-50 border rounded-lg px-2.5 py-2.5 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89] transition-colors"
                  :class="bookingErrors.reservationTime ? 'border-red-400' : 'border-gray-200'"
                />
                <button @click="setQuickBookingTime(15)" type="button" class="px-2 bg-gray-100 hover:bg-gray-200 rounded-lg text-[10px] font-black text-gray-600 transition-colors shrink-0">+15p</button>
                <button @click="setQuickBookingTime(60)" type="button" class="px-2 bg-gray-100 hover:bg-gray-200 rounded-lg text-[10px] font-black text-gray-600 transition-colors shrink-0">+1g</button>
              </div>
              <p v-if="bookingErrors.reservationTime" class="text-[10px] text-red-500 font-semibold">{{ bookingErrors.reservationTime }}</p>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3.5">
            <div class="space-y-1">
              <label class="text-[9px] font-black text-gray-400 uppercase">{{ t('admin_floors.booking.guests') }} <span class="text-red-500">*</span></label>
              <div class="flex items-center gap-1.5">
                <button @click="decrementGuests" type="button" class="w-9 h-9 rounded-lg border border-gray-200 hover:bg-gray-50 flex items-center justify-center text-gray-600 font-black transition-colors shrink-0">−</button>
                <input
                  type="number"
                  v-model.number="newBookingForm.guestCount"
                  min="1"
                  max="50"
                  class="flex-1 bg-gray-50 border rounded-lg px-2 py-2.5 font-bold text-gray-800 text-center focus:outline-none focus:ring-1 focus:ring-[#FF7B89] transition-colors"
                  :class="bookingErrors.guestCount ? 'border-red-400' : 'border-gray-200'"
                />
                <button @click="incrementGuests" type="button" class="w-9 h-9 rounded-lg border border-gray-200 hover:bg-gray-50 flex items-center justify-center text-gray-600 font-black transition-colors shrink-0">+</button>
              </div>
              <p v-if="bookingErrors.guestCount" class="text-[10px] text-red-500 font-semibold">{{ bookingErrors.guestCount }}</p>
            </div>
            <div class="space-y-1">
              <label class="text-[9px] font-black text-gray-400 uppercase">{{ t('admin_floors.booking.assign') }} <span class="text-gray-300 font-normal">(tùy chọn)</span></label>
              <select
                v-model="newBookingForm.assignedTable"
                class="w-full bg-gray-50 border border-gray-200 rounded-lg px-3 py-2.5 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89] transition-colors"
              >
                <option value="">{{ t('admin_floors.booking.unassigned') }}</option>
                <optgroup v-for="area in areas" :key="area.name" :label="area.name">
                  <option
                    v-for="tbl in area.tables"
                    :key="tbl.code"
                    :value="tbl.code"
                    :disabled="tbl.status !== 'Available' && tbl.code !== newBookingForm.assignedTable"
                  >{{ tbl.code }} ({{ t('admin_floors.table.capacity') }} {{ tbl.capacity }} {{ t('admin_floors.booking.seats') }})</option>
                </optgroup>
              </select>
            </div>
          </div>

          <div class="space-y-1">
            <label class="text-[9px] font-black text-gray-400 uppercase">{{ t('admin_floors.booking.notes') }}</label>
            <textarea
              v-model="newBookingForm.notes"
              :placeholder="i18n.t('admin_floors.placeholder.notes')"
              class="w-full bg-gray-50 border border-gray-200 rounded-lg px-3 py-2.5 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89] h-16 resize-none transition-colors"
            ></textarea>
          </div>
        </div>

        <div class="flex gap-3 select-none">
          <button @click="isCreateBookingModalOpen = false" class="flex-1 py-2.5 rounded-xl border border-gray-250 bg-white hover:bg-gray-50 text-gray-700 text-[11px] font-bold transition-colors">{{ t('admin_floors.action.cancel') }}</button>
          <button
            @click="saveNewBooking"
            :disabled="isSubmittingBooking"
            class="flex-1 py-2.5 rounded-xl bg-gradient-to-r from-[#FF7B89] to-[#FF5A6E] hover:from-[#FF5A6E] hover:to-[#FF4055] text-white text-[11px] font-black transition-all shadow-sm disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-1.5"
          >
            <svg v-if="isSubmittingBooking" class="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
            </svg>
            <span>{{ isSubmittingBooking ? 'Đang lưu...' : t('admin_floors.action.save') }}</span>
          </button>
        </div>
      </div>
    </div>

    <!-- MODAL 3: QUICK OPEN TABLE (WALK-IN) -->
    <div v-if="isQuickOpenModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm" @click="isQuickOpenModalOpen = false"></div>
      <div class="bg-white border-2 border-pink-100 rounded-3xl w-full max-w-md shadow-2xl p-6 z-10 relative animate-fade-in text-xs font-bold text-gray-700">
        <button @click="isQuickOpenModalOpen = false" class="absolute top-4 right-4 w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 hover:text-gray-800 flex items-center justify-center transition-colors font-bold text-sm select-none">✕</button>
        <h3 class="text-lg font-black text-gray-900 tracking-tight mb-4 flex items-center gap-1.5 select-none border-b border-gray-100 pb-2">🍽️ {{ t('admin_floors.action.open_walkin') }}</h3>

        <div class="space-y-4 mb-5">
          <div class="space-y-1">
            <label class="text-[9px] font-black text-gray-400 uppercase">{{ t('admin_floors.modal.select_empty') }}</label>
            <select
              v-model="quickOpenForm.tableCode"
              class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2.5 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
            >
              <option value="">{{ t('admin_floors.modal.click_empty') }}</option>
              <optgroup v-for="area in areas" :key="area.name" :label="area.name">
                <option v-for="tbl in area.tables" :key="tbl.code" :value="tbl.code" v-show="tbl.status === 'Available'">
                  {{ t('admin_floors.table.unit') }} {{ tbl.code }} ({{ tbl.capacity }})
                </option>
              </optgroup>
            </select>
          </div>
          <div class="space-y-1">
            <label class="text-[9px] font-black text-gray-400 uppercase">{{ t('admin_floors.booking.optional_name') }}</label>
            <input
              type="text"
              v-model="quickOpenForm.customerName"
              :placeholder="i18n.t('admin_floors.placeholder.optional_name')"
              class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
            />
          </div>
          <div class="grid grid-cols-2 gap-3.5">
            <div class="space-y-1">
              <label class="text-[9px] font-black text-gray-400 uppercase">{{ t('admin_floors.booking.actual_guests') }}</label>
              <input
                type="number"
                v-model="quickOpenForm.guestCount"
                :placeholder="i18n.t('admin_floors.placeholder.guests')"
                class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
              />
            </div>
            <div class="space-y-1">
              <label class="text-[9px] font-black text-gray-400 uppercase">{{ t('admin_floors.booking.initial_bill') }}</label>
              <div class="w-full bg-rose-50 border border-rose-200 rounded-lg px-2.5 py-2 font-extrabold text-rose-700 text-sm">{{ liveBillTotal }}</div>
            </div>
          </div>
        </div>

        <div class="flex gap-3 select-none">
          <button @click="isQuickOpenModalOpen = false" class="flex-1 py-2 rounded-xl border border-gray-250 bg-white hover:bg-gray-50 text-gray-700 text-[11px] font-bold transition-colors">{{ t('admin_floors.action.close_btn') }}</button>
          <button @click="saveQuickOpen" class="flex-1 py-2 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-[11px] font-black transition-colors shadow-sm">{{ t('admin_floors.action.open_serving') }}</button>
        </div>
      </div>
    </div>

    <!-- MODAL 4: QUICK CHECK-IN (ARRIVED) -->
    <div v-if="isQuickArrivedModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm" @click="isQuickArrivedModalOpen = false"></div>
      <div class="bg-white border-2 border-pink-100 rounded-3xl w-full max-w-md shadow-2xl p-6 z-10 relative animate-fade-in text-xs font-bold text-gray-700">
        <button @click="isQuickArrivedModalOpen = false" class="absolute top-4 right-4 w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 hover:text-gray-800 flex items-center justify-center transition-colors font-bold text-sm select-none">✕</button>
        <h3 class="text-lg font-black text-gray-900 tracking-tight mb-4 flex items-center gap-1.5 select-none border-b border-gray-100 pb-2">🚶 {{ t('admin_floors.action.receive_checkin') }}</h3>

        <div class="space-y-4 mb-5">
          <div class="space-y-1">
            <label class="text-[9px] font-black text-gray-400 uppercase">{{ t('admin_floors.modal.select_booking') }}</label>
            <select
              v-model="quickArrivedForm.bookingId"
              class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2.5 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
            >
              <option value="">{{ t('admin_floors.modal.click_booking') }}</option>
              <option
                v-for="b in bookings.filter(bx => bx.date === getFormattedSelectedDate && bx.status === 'Waiting')"
                :key="b.id"
                :value="b.id"
              >{{ b.reservationTime }} - {{ b.customerName }} (Bàn: {{ b.assignedTable || 'Chưa xếp' }})</option>
              <option
                v-for="r in receptionReservations.filter(rx => rx.reservationDate === getFormattedSelectedDate && rx.status === 'PENDING')"
                :key="r.id"
                :value="r.id"
              >{{ r.reservationTime }} - {{ r.customerName }} (Bàn: {{ r.tableCode || 'Chưa xếp' }})</option>
            </select>
          </div>
        </div>

        <div class="flex gap-3 select-none">
          <button @click="isQuickArrivedModalOpen = false" class="flex-1 py-2 rounded-xl border border-gray-250 bg-white hover:bg-gray-50 text-gray-700 text-[11px] font-bold transition-colors">{{ t('admin_floors.action.cancel') }}</button>
          <button @click="saveQuickArrived" class="flex-1 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-[11px] font-black transition-colors shadow-sm">{{ t('admin_floors.action.welcome_guest') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18nStore } from '@/stores/i18n'
const i18n = useI18nStore()
import Swal from 'sweetalert2'
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, reactive, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useRestaurantStore } from '@/stores/restaurantStore'
import { storeToRefs } from 'pinia'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/composables/useAuth'
import { useUnsavedGuard } from '@/composables/useUnsavedGuard'
import { useCheckout } from '@/composables/useCheckout'
import { useRealtime } from '@/composables/useRealtime'
import { useReceptionSync } from '@/composables/useReceptionSync'

// ─── Auth & Store ────────────────────────────────────────────────────────────
const router = useRouter()
const restaurantStore = useRestaurantStore()
const { bookings } = storeToRefs(restaurantStore)
const { branchId: activeBranchId } = useAuth()

// ─── Reception Store (shared with ReservationDetailView) ────────────────────
const {
  reservations: receptionReservations,
  waitingReservations: receptionWaiting,
  addReservation: receptionAddReservation,
  assignTable: receptionAssignTable,
  updateReservation: receptionUpdateReservation,
  loadReservations: loadReceptionReservations,
} = useReceptionSync()

// ─── Types ───────────────────────────────────────────────────────────────────
interface TableInfo {
  code: string
  status: 'Available' | 'Reserved' | 'Arrived' | 'Serving' | 'Maintenance'
  id?: string
  metadata?: any
  capacity: number
  customerName?: string
  billAmount?: string
  occupiedDuration?: string
  checkInTime?: string
}

interface AreaInfo {
  name: string
  description: string
  tables: TableInfo[]
}

interface Booking {
  id: string
  bookingNumber: string
  customerName: string
  phone: string
  adults: number
  children: number
  reservationTime: string
  assignedTable: string
  notes: string
  status: 'Waiting' | 'Arrived' | 'Seated' | 'Completed' | 'Cancelled'
  date: string
}

// ─── State ───────────────────────────────────────────────────────────────────
const areas = ref<AreaInfo[]>(
  restaurantStore.areas.map(a => ({
    name: a.name,
    description: a.description,
    tables: a.tables.map(t => ({ ...t })),
  })),
)

const selectedZone = ref('All')
const isZoneDropdownOpen = ref(false)
const activeShift = ref<'all' | 'morning' | 'lunch' | 'evening'>('all')

// ─── Timeline Slider ─────────────────────────────────────────────────────────
const timelineTimeRaw = ref(1080)
const timelineTime = ref(1080)
let timelineDebounce: number | null = null

const inputTimelineTime = computed({
  get() {
    const h = Math.floor(timelineTime.value / 60)
    const m = timelineTime.value % 60
    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`
  },
  set(val: string) {
    if (!val) return
    const [h, m] = val.split(':').map(Number)
    const next = h * 60 + m
    timelineTime.value = next
    timelineTimeRaw.value = next
    checkConflicts()
  },
})

function commitTimelineTime() {
  if (timelineDebounce != null) clearTimeout(timelineDebounce)
  timelineDebounce = window.setTimeout(() => {
    timelineDebounce = null
    timelineTime.value = timelineTimeRaw.value
    checkConflicts()
  }, 100)
}

function resetTimeline() {
  const now = new Date()
  const next = now.getHours() * 60 + now.getMinutes()
  timelineTime.value = next
  timelineTimeRaw.value = next
  conflictTables.value.clear()
}

function formatTime(minutes: number): string {
  const h = Math.floor(minutes / 60).toString().padStart(2, '0')
  const m = (minutes % 60).toString().padStart(2, '0')
  return `${h}:${m}`
}

// ─── Conflict Detection ──────────────────────────────────────────────────────
const conflictTables = ref<Set<string>>(new Set())

function checkConflicts() {
  const formattedToday = getFormattedSelectedDate.value

  // Legacy bookings from restaurantStore
  const todaysBookings = bookings.value.filter(b => b.date === formattedToday && b.status !== 'Cancelled')
  // Reservations from receptionStore (shared with ReservationDetailView)
  const todaysReceptionRes = receptionReservations.value.filter(
    r => r.reservationDate === formattedToday && r.status !== 'CANCELLED' && r.status !== 'COMPLETED',
  )

  const next = new Set<string>()

  // Check legacy bookings
  todaysBookings.forEach(b => {
    if (!b.assignedTable) return
    const [bh, bm] = b.reservationTime.split(':').map(Number)
    const bookingMin = bh * 60 + bm
    if (timelineTime.value >= bookingMin - 60 && timelineTime.value < bookingMin) {
      next.add(b.assignedTable)
    }
  })

  // Check receptionStore reservations
  todaysReceptionRes.forEach(r => {
    if (!r.tableCode) return
    const [bh, bm] = r.reservationTime.split(':').map(Number)
    const bookingMin = bh * 60 + bm
    if (timelineTime.value >= bookingMin - 60 && timelineTime.value < bookingMin) {
      next.add(r.tableCode)
    }
  })

  conflictTables.value = next
}

// ─── Drag & Drop ─────────────────────────────────────────────────────────────
const isDragOverTable = ref<string | null>(null)
const isInvalidDropTable = ref<string | null>(null)
let draggedReservation: Booking | null = null

function handleDragStart(event: DragEvent, reservation: Booking) {
  draggedReservation = reservation
  event.dataTransfer!.effectAllowed = 'move'
  event.dataTransfer!.setData('application/json', JSON.stringify(reservation))
  setTimeout(() => {
    const target = event.target as HTMLElement
    if (target) target.classList.add('opacity-50')
  }, 0)
}

function handleDragEnd(event: DragEvent) {
  const target = event.target as HTMLElement
  if (target) target.classList.remove('opacity-50')
  draggedReservation = null
  isDragOverTable.value = null
  isInvalidDropTable.value = null
}

function handleDragOver(event: DragEvent, table: TableInfo) {
  event.preventDefault()
  const tableId = table.id || table.code
  const canDrop = table.status === 'Available' && !conflictTables.value.has(table.code)
  event.dataTransfer!.dropEffect = canDrop ? 'move' : 'none'
}

function handleDragEnter(event: DragEvent, table: TableInfo) {
  event.preventDefault()
  const tableId = table.id || table.code
  if (table.status === 'Available' && !conflictTables.value.has(table.code)) {
    isDragOverTable.value = tableId
  }
}

function handleDragLeave(event: DragEvent, table: TableInfo) {
  const tableId = table.id || table.code
  if (isDragOverTable.value === tableId) {
    isDragOverTable.value = null
  }
}

function handleDrop(event: DragEvent, table: TableInfo) {
  event.preventDefault()
  const tableId = table.id || table.code
  isDragOverTable.value = null

  if (table.status !== 'Available' || conflictTables.value.has(table.code)) {
    isInvalidDropTable.value = tableId
    setTimeout(() => { isInvalidDropTable.value = null }, 600)
    Swal.fire({
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 2500,
      timerProgressBar: true,
      icon: 'warning',
      title: t('reception_floors.invalid_drop'),
    })
    return
  }

  let reservation: Booking | null = null
  try {
    const data = event.dataTransfer!.getData('application/json')
    reservation = JSON.parse(data) as Booking
  } catch {
    return
  }

  if (!reservation) return

  // Capacity check
  const totalGuests = reservation.adults + reservation.children
  if (totalGuests > table.capacity) {
    isInvalidDropTable.value = tableId
    setTimeout(() => { isInvalidDropTable.value = null }, 600)
    Swal.fire({
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 3000,
      timerProgressBar: true,
      icon: 'warning',
      title: `Bàn chỉ chứa ${table.capacity} người, khách có ${totalGuests} người`,
    })
    return
  }

  // Update the table's visual state immediately
  table.status = 'Reserved'
  table.customerName = reservation.customerName

  // Check if this reservation came from receptionStore (has a code like RESxxx or rNN)
  const receptionRes = receptionReservations.value.find(r => r.id === reservation.id)
  if (receptionRes) {
    // Assign via receptionStore — this updates the shared state so it disappears
    // from the waiting list and the table assignment persists across views
    receptionAssignTable(receptionRes.id, table.code, table.id || table.code)
  } else {
    // Legacy: reservation came from restaurantStore.bookings
    reservation.assignedTable = table.code
  }

  // Immediate success feedback
  Swal.fire({
    toast: true,
    position: 'top-end',
    showConfirmButton: false,
    timer: 2000,
    timerProgressBar: true,
    icon: 'success',
    title: t('reception_floors.assign_success'),
  })
}

// ─── Unassigned Reservations (Draggable list) ────────────────────────────────
// Reads from receptionStore (shared with ReservationDetailView) so reservations
// created on the detail page appear here instantly via Pinia reactivity.
// Also merges legacy restaurantStore bookings for backward compatibility.
const unassignedReservations = computed(() => {
  const formattedDate = getFormattedSelectedDate.value

  // 1. Reservations from receptionStore (primary source — written by ReservationDetailView)
  const fromReception = receptionWaiting.value
    .filter(r => r.reservationDate === formattedDate)
    .map(r => ({
      id: r.id,
      bookingNumber: r.code,
      customerName: r.customerName,
      phone: r.customerPhone,
      adults: r.guests,
      children: r.children,
      reservationTime: r.reservationTime,
      assignedTable: '',
      notes: r.notes || '',
      status: 'Waiting' as Booking['status'],
      date: r.reservationDate,
    }))

  // 2. Legacy bookings from restaurantStore (secondary — for backward compat with mock data)
  const fromRestaurant = bookings.value
    .filter(b => b.date === formattedDate && b.status === 'Waiting' && !b.assignedTable)

  // Merge, deduplicate by customerName + reservationTime, sort by time
  const seen = new Set<string>()
  const merged = [...fromReception, ...fromRestaurant]
    .filter(b => {
      const key = `${b.customerName}-${b.reservationTime}`
      if (seen.has(key)) return false
      seen.add(key)
      return true
    })
    .sort((a, b) => a.reservationTime.localeCompare(b.reservationTime))

  return merged
})

// ─── Zone Options ────────────────────────────────────────────────────────────
const zoneOptions = computed(() => {
  const base = [{ label: t('admin_floors.filter.all'), value: 'All' }]
  const dynamicZones = areas.value.map(a => ({ label: a.name, value: a.name }))
  return [...base, ...dynamicZones]
})

const selectedZoneLabel = computed(() => {
  const zone = zoneOptions.value.find(o => o.value === selectedZone.value)
  return zone ? zone.label : ''
})

// ─── Simulated Areas (table states based on timeline) ────────────────────────
// Merges table assignments from both receptionStore (shared) and restaurantStore (legacy)
const simulatedAreas = computed<AreaInfo[]>(() => {
  const formattedToday = getFormattedSelectedDate.value
  const todaysBookings = bookings.value.filter(b => b.date === formattedToday)

  // Build a unified list of table-attached reservations from receptionStore
  const todaysReceptionRes = receptionReservations.value
    .filter(r => r.reservationDate === formattedToday && r.status !== 'CANCELLED' && r.status !== 'COMPLETED' && r.tableCode)
    .map(r => ({
      assignedTable: r.tableCode!,
      customerName: r.customerName,
      reservationTime: r.reservationTime,
      status: 'Waiting' as const,
    }))

  return areas.value.map(area => ({
    ...area,
    tables: area.tables.map(table => {
      // Match from both legacy bookings and receptionStore reservations
      const tableBookings = [
        ...todaysBookings.filter(b => b.assignedTable === table.code && b.status !== 'Cancelled'),
        ...todaysReceptionRes.filter(b => b.assignedTable === table.code),
      ]

      if (tableBookings.length === 0) return { ...table }

      let computedStatus = table.status
      let computedCustomer = table.customerName
      let computedBill = table.billAmount
      let computedCheckIn = table.checkInTime
      let computedDuration = table.occupiedDuration
      let foundActive = false

      for (const booking of tableBookings) {
        const [h, m] = booking.reservationTime.split(':').map(Number)
        const bookingMin = h * 60 + m
        const currentMin = timelineTime.value

        if (currentMin >= bookingMin - 60 && currentMin < bookingMin) {
          computedStatus = 'Reserved'
          computedCustomer = booking.customerName
          computedBill = ''
          computedCheckIn = ''
          computedDuration = ''
          foundActive = true
          break
        } else if (currentMin >= bookingMin && currentMin < bookingMin + 15) {
          computedStatus = 'Arrived'
          computedCustomer = booking.customerName
          foundActive = true
          break
        } else if (currentMin >= bookingMin + 15 && currentMin < bookingMin + 120) {
          computedStatus = 'Serving'
          computedCustomer = booking.customerName
          computedBill = '—'
          computedCheckIn = booking.reservationTime
          computedDuration = `${currentMin - bookingMin} phút`
          foundActive = true
          break
        }
      }

      if (foundActive) {
        return { ...table, status: computedStatus, customerName: computedCustomer, billAmount: computedBill, checkInTime: computedCheckIn, occupiedDuration: computedDuration }
      }
      // Assigned reservation exists but timeline doesn't match — still show as Reserved
      if (tableBookings.length > 0) {
        return { ...table, status: 'Reserved', customerName: tableBookings[0].customerName, billAmount: '', checkInTime: '', occupiedDuration: '' }
      }
      return { ...table, status: 'Available', customerName: '', billAmount: '', checkInTime: '', occupiedDuration: '' }
    }),
  }))
})

const filteredAreas = computed(() => {
  if (selectedZone.value === 'All') return simulatedAreas.value
  return simulatedAreas.value.filter(a => a.name === selectedZone.value)
})

// ─── Calendar ─────────────────────────────────────────────────────────────────
const selectedDate = ref(new Date())
const currentYear = ref(2026)
const currentMonth = ref(5)
const monthNames = ['Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12']

const getFormattedSelectedDate = computed(() => {
  const y = selectedDate.value.getFullYear()
  const m = String(selectedDate.value.getMonth() + 1).padStart(2, '0')
  const d = String(selectedDate.value.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
})

const selectedDateLabelFormatted = computed(() => {
  return selectedDate.value.toLocaleDateString('vi-VN', { weekday: 'long', year: 'numeric', month: 'numeric', day: 'numeric' })
})

const calendarDays = computed(() => {
  const year = currentYear.value
  const month = currentMonth.value
  const firstDayIndex = new Date(year, month, 1).getDay()
  const adjustedFirstDayIndex = (firstDayIndex + 6) % 7
  const totalDays = new Date(year, month + 1, 0).getDate()
  const prevMonthTotalDays = new Date(year, month, 0).getDate()
  const days: { day: number; month: number; year: number; isCurrentMonth: boolean }[] = []

  for (let i = adjustedFirstDayIndex - 1; i >= 0; i--) {
    days.push({ day: prevMonthTotalDays - i, month: month === 0 ? 11 : month - 1, year: month === 0 ? year - 1 : year, isCurrentMonth: false })
  }
  for (let i = 1; i <= totalDays; i++) {
    days.push({ day: i, month, year, isCurrentMonth: true })
  }
  const remaining = 42 - days.length
  for (let i = 1; i <= remaining; i++) {
    days.push({ day: i, month: month === 11 ? 0 : month + 1, year: month === 11 ? year + 1 : year, isCurrentMonth: false })
  }
  return days
})

function prevMonth() {
  if (currentMonth.value === 0) { currentMonth.value = 11; currentYear.value-- } else { currentMonth.value-- }
}
function nextMonth() {
  if (currentMonth.value === 11) { currentMonth.value = 0; currentYear.value++ } else { currentMonth.value++ }
}
function selectCalendarDay(d: { day: number; month: number; year: number }) {
  selectedDate.value = new Date(d.year, d.month, d.day)
  checkConflicts()
}
function isSameDate(date: Date, year: number, month: number, day: number) {
  return date.getFullYear() === year && date.getMonth() === month && date.getDate() === day
}

// ─── Shift Logic ──────────────────────────────────────────────────────────────
function getBookingShift(timeStr: string): 'morning' | 'lunch' | 'evening' {
  const [hour] = timeStr.split(':').map(Number)
  if (hour >= 6 && hour < 11) return 'morning'
  if (hour >= 11 && hour < 14) return 'lunch'
  return 'evening'
}

function getShiftCount(shift: string) {
  const formattedDate = getFormattedSelectedDate.value

  // Legacy restaurantStore bookings
  let list = bookings.value.filter(b => b.date === formattedDate)
  // ReceptionStore reservations (shared with ReservationDetailView)
  const receptionList = receptionReservations.value
    .filter(r => r.reservationDate === formattedDate && r.status !== 'CANCELLED' && r.status !== 'COMPLETED')
    .map(r => ({
      assignedTable: r.tableCode || '',
      reservationTime: r.reservationTime,
      customerName: r.customerName,
    }))

  // Merge both lists
  type MergedBooking = { assignedTable: string; reservationTime: string; customerName: string }
  const merged: MergedBooking[] = [
    ...list.map(b => ({ assignedTable: b.assignedTable, reservationTime: b.reservationTime, customerName: b.customerName })),
    ...receptionList,
  ]

  let filtered = merged
  if (selectedZone.value !== 'All') {
    filtered = filtered.filter(b => {
      if (!b.assignedTable) return false
      return getTableArea(b.assignedTable) === selectedZone.value
    })
  }
  if (shift === 'all') return filtered.length
  return filtered.filter(b => getBookingShift(b.reservationTime) === shift).length
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
function getTableArea(tableCode: string): string | null {
  for (const area of areas.value) {
    if (area.tables.some(t => t.code === tableCode)) return area.name
  }
  return null
}

function getZoneTableCount(zoneValue: string) {
  if (zoneValue === 'All') return areas.value.reduce((acc, a) => acc + a.tables.length, 0)
  const area = areas.value.find(a => a.name === zoneValue)
  return area ? area.tables.length : 0
}

function getTableReservationTime(tableCode: string) {
  const formattedToday = getFormattedSelectedDate.value
  // Check legacy restaurantStore bookings first
  const match = bookings.value.find(
    b => b.date === formattedToday && b.assignedTable === tableCode && b.status !== 'Seated' && b.status !== 'Completed' && b.status !== 'Cancelled',
  )
  if (match) return match.reservationTime
  // Check receptionStore reservations
  const receptionMatch = receptionReservations.value.find(
    r => r.reservationDate === formattedToday && r.tableCode === tableCode && r.status !== 'SEATED' && r.status !== 'COMPLETED' && r.status !== 'CANCELLED',
  )
  return receptionMatch ? receptionMatch.reservationTime : null
}

function getTableArrivalTime(tableCode: string) {
  const formattedToday = getFormattedSelectedDate.value
  // Check legacy restaurantStore bookings
  const match = bookings.value.find(b => b.date === formattedToday && b.assignedTable === tableCode && b.status === 'Arrived')
  if (match) return match.reservationTime
  // Check receptionStore (CONFIRMED status maps to Arrived conceptually)
  const receptionMatch = receptionReservations.value.find(
    r => r.reservationDate === formattedToday && r.tableCode === tableCode && r.status === 'CONFIRMED',
  )
  return receptionMatch ? receptionMatch.reservationTime : null
}

function getTableByCode(code: string): TableInfo | null {
  for (const area of areas.value) {
    const found = area.tables.find(t => t.code === code)
    if (found) return found
  }
  return null
}

function getBadgeColorClass(status: string) {
  if (!status) return 'bg-gray-100 text-gray-400 border-gray-200'
  const s = status.toLowerCase()
  if (s === 'available') return 'bg-emerald-100 text-emerald-700 border-emerald-200'
  if (s === 'reserved') return 'bg-amber-100 text-amber-700 border-amber-200'
  if (s === 'arrived') return 'bg-blue-100 text-blue-700 border-amber-200'
  if (s === 'serving' || s === 'occupied') return 'bg-red-100 text-red-700 border-red-200'
  if (s === 'maintenance') return 'bg-gray-100 text-gray-600 border-gray-200'
  return 'bg-gray-100 text-gray-500 border-gray-200'
}

function translateTableStatus(status: string) {
  if (!status) return ''
  const s = status.toLowerCase()
  switch (s) {
    case 'available': return t('admin_floors.status.badge.empty')
    case 'reserved': return t('admin_floors.status.badge.reserved')
    case 'arrived': return t('admin_floors.status.badge.arrived')
    case 'occupied':
    case 'serving': return t('admin_floors.status.badge.serving')
    case 'maintenance': return t('admin_floors.status.badge.maintenance')
    default: return status
  }
}

function getTableColorClass(table: TableInfo) {
  if (conflictTables.value.has(table.code)) {
    return 'bg-orange-50 border-orange-300 hover:border-orange-500'
  }
  switch (table.status) {
    case 'Available': return 'bg-emerald-50/40 border-emerald-200 hover:border-emerald-400'
    case 'Reserved': return 'bg-amber-50/40 border-amber-200 hover:border-amber-400'
    case 'Arrived': return 'bg-blue-50/40 border-blue-200 hover:border-blue-400'
    case 'Serving': return 'bg-rose-50/40 border-rose-200 hover:border-rose-450'
    case 'Maintenance': return 'bg-yellow-50/40 border-yellow-200 hover:border-yellow-450'
    default: return 'bg-gray-50 border-gray-200'
  }
}

// ─── Stats ─────────────────────────────────────────────────────────────────────
const stats = computed(() => {
  let totalT = 0, availT = 0, servingT = 0, totalS = 0, availS = 0
  simulatedAreas.value.forEach(area => {
    area.tables.forEach(table => {
      totalT++
      totalS += table.capacity
      if (table.status === 'Available') { availT++; availS += table.capacity }
      else if (table.status === 'Serving') servingT++
    })
  })
  return { totalTables: totalT, availableTables: availT, servingTables: servingT, totalSeats: totalS, availableSeats: availS }
})

const sidebarStats = computed(() => {
  const formattedToday = getFormattedSelectedDate.value
  // Legacy restaurantStore bookings
  let list = bookings.value.filter(b => b.date === formattedToday)
  if (selectedZone.value !== 'All') {
    list = list.filter(b => {
      if (!b.assignedTable) return false
      return getTableArea(b.assignedTable) === selectedZone.value
    })
  }
  // Add receptionStore reservations (shared with ReservationDetailView)
  let receptionList = receptionReservations.value.filter(
    r => r.reservationDate === formattedToday && r.status !== 'CANCELLED' && r.status !== 'COMPLETED',
  )
  if (selectedZone.value !== 'All') {
    receptionList = receptionList.filter(r => {
      if (!r.tableCode) return false
      return getTableArea(r.tableCode) === selectedZone.value
    })
  }
  const receptionArrived = receptionList.filter(r => r.status === 'CONFIRMED').length
  const receptionWaiting = receptionList.filter(r => r.status === 'PENDING' || r.status === 'CONFIRMED').length

  return {
    total: list.length + receptionList.length,
    arrived: list.filter(b => b.status === 'Arrived').length + receptionArrived,
    waiting: list.filter(b => b.status === 'Waiting' || b.status === 'Arrived').length + receptionWaiting,
  }
})

// ─── Zone Summary (right column) ──────────────────────────────────────────────
const zoneSummary = computed(() => {
  const base = [{ label: t('admin_floors.filter.all'), value: 'All' }]
  const dynamicZones = areas.value.map(a => ({ label: a.name, value: a.name }))
  return [...base, ...dynamicZones].map(zone => ({
    ...zone,
    serving: getZoneActiveTablesCount(zone.value),
    reserved: getZoneBookingsCount(zone.value),
    revenue: getZoneRevenue(zone.value),
  }))
})

function getZoneActiveTablesCount(zoneName: string) {
  let count = 0
  simulatedAreas.value.forEach(area => {
    if (zoneName === 'All' || area.name === zoneName) {
      area.tables.forEach(t => { if (t.status === 'Serving') count++ })
    }
  })
  return count
}

function getZoneBookingsCount(zoneName: string) {
  const formattedToday = getFormattedSelectedDate.value

  // Legacy restaurantStore bookings
  let list = bookings.value.filter(b => b.date === formattedToday && b.status !== 'Cancelled')
  // ReceptionStore reservations (shared with ReservationDetailView)
  const receptionList = receptionReservations.value.filter(
    r => r.reservationDate === formattedToday && r.status !== 'CANCELLED' && r.status !== 'COMPLETED',
  )

  let count = list.length

  if (zoneName !== 'All') {
    // Legacy: filter by assignedTable zone
    count = list.filter(b => {
      if (!b.assignedTable) return false
      return getTableArea(b.assignedTable) === zoneName
    }).length
    // Reception: filter by tableCode zone
    count += receptionList.filter(r => {
      if (!r.tableCode) return false
      return getTableArea(r.tableCode) === zoneName
    }).length
  } else {
    count += receptionList.length
  }

  return count
}

function getZoneRevenue(zoneName: string) {
  let sum = 0
  simulatedAreas.value.forEach(area => {
    if (zoneName === 'All' || area.name === zoneName) {
      area.tables.forEach(t => {
        if (t.status === 'Serving' && t.billAmount) {
          const val = parseInt(t.billAmount.replace(/\D/g, '')) || 0
          sum += val
        }
      })
    }
  })
  if (sum === 0) return '0đ'
  if (sum >= 1000000) return (sum / 1000000).toFixed(1) + 'M'
  return (sum / 1000).toFixed(0) + 'K'
}

// ─── System Clock ──────────────────────────────────────────────────────────────
const currentTime = ref('')
let systemClockInterval: number | null = null

function updateSystemClock() {
  const now = new Date()
  currentTime.value = now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
}

function scheduleSystemClock() {
  if (systemClockInterval != null) clearInterval(systemClockInterval)
  const fast = isTableModalOpen.value
  systemClockInterval = setInterval(updateSystemClock, fast ? 1000 : 30_000) as unknown as number
}

// ─── Live Bill Total ──────────────────────────────────────────────────────────
const { previewTableSummary, clearTableCache } = useCheckout()
const { watchTable } = useRealtime()
const billTotalsCache = ref<Record<string, { subtotal: number; grand_total: number; loading: boolean; error: string | null }>>({})

const liveBillTotal = computed(() => {
  const code = selectedTableForModal.value?.code ?? ''
  const tbl = code ? getTableByCode(code) : null
  if (!tbl) return '0đ'
  const tableId = (tbl as any).id as string | undefined
  if (!tableId) return '0đ'
  const cached = billTotalsCache.value[tableId]
  if (cached?.loading) return '…'
  if (cached?.error) return cached.error
  if (cached) return `${cached.grand_total.toLocaleString('vi-VN')}đ`
  return '—'
})

async function refreshBillTotalForTable(tableId: string) {
  if (!activeBranchId.value) return
  billTotalsCache.value = { ...billTotalsCache.value, [tableId]: { subtotal: 0, grand_total: 0, loading: true, error: null } }
  try {
    const preview = await previewTableSummary(activeBranchId.value, tableId)
    if (preview.ok && preview.totals) {
      billTotalsCache.value = { ...billTotalsCache.value, [tableId]: { subtotal: preview.totals.subtotal, grand_total: preview.totals.grand_total, loading: false, error: null } }
    } else {
      billTotalsCache.value = { ...billTotalsCache.value, [tableId]: { subtotal: 0, grand_total: 0, loading: false, error: preview.error ?? '—' } }
    }
  } catch (e: any) {
    billTotalsCache.value = { ...billTotalsCache.value, [tableId]: { subtotal: 0, grand_total: 0, loading: false, error: e?.message ?? 'lỗi' } }
  }
}

const liveOccupiedDuration = computed(() => {
  const code = selectedTableForModal.value?.code ?? ''
  const tbl = code ? getTableByCode(code) : null
  if (!tbl || !tbl.checkInTime) return '—'
  const open = parseCheckInTime(tbl.checkInTime)
  if (!open) return tbl.checkInTime
  const elapsedMin = Math.max(0, Math.round((now.value - open) / 60000))
  if (elapsedMin < 60) return `${elapsedMin} phút`
  const h = Math.floor(elapsedMin / 60)
  const m = elapsedMin % 60
  return `${h}h ${m}p`
})

const now = ref(Date.now())
let durationTimer: ReturnType<typeof setInterval> | null = null
function startDurationTicker() {
  if (durationTimer) return
  durationTimer = setInterval(() => { now.value = Date.now() }, 30_000)
}
function stopDurationTicker() {
  if (!durationTimer) return
  clearInterval(durationTimer)
  durationTimer = null
}

function parseCheckInTime(raw: string): number | null {
  if (/^\d{1,2}:\d{2}$/.test(raw)) {
    const [h, m] = raw.split(':').map(Number)
    const d = new Date()
    d.setHours(h, m, 0, 0)
    return d.getTime()
  }
  const ts = Date.parse(raw)
  return Number.isNaN(ts) ? null : ts
}

// ─── Modal 1: Table Details ───────────────────────────────────────────────────
const isTableModalOpen = ref(false)
const selectedTableForModal = ref<(TableInfo & { areaName: string }) | null>(null)
const tableModalForm = ref({ customerName: '', status: 'Available' as TableInfo['status'] })
const tableModalBaseline = ref({ customerName: '', status: 'Available' as TableInfo['status'] })
const { confirmIfDirty: confirmTableDirty } = useUnsavedGuard(tableModalForm, tableModalBaseline)

// Watches that reference selectedTableForModal must come after its declaration.
watch(() => selectedTableForModal.value?.code, (newCode, oldCode) => {
  if (newCode === oldCode) return
  const tbl = newCode ? getTableByCode(newCode) : null
  const tableId = (tbl as any)?.id as string | undefined
  if (tableId) refreshBillTotalForTable(tableId)
})

watchTable<Record<string, unknown>>('orders', '*', () => {
  const code = selectedTableForModal.value?.code
  if (code) {
    const tbl = getTableByCode(code)
    const tableId = (tbl as any)?.id as string | undefined
    if (tableId) clearTableCache(tableId)
  }
})
watchTable<Record<string, unknown>>('order_items', '*', () => {
  const code = selectedTableForModal.value?.code
  if (code) {
    const tbl = getTableByCode(code)
    const tableId = (tbl as any)?.id as string | undefined
    if (tableId) clearTableCache(tableId)
  }
})

function openTableModal(areaName: string, table: TableInfo) {
  selectedTableForModal.value = { ...table, areaName }
  tableModalForm.value = { customerName: table.customerName || '', status: table.status }
  tableModalBaseline.value = { ...tableModalForm.value }
  isTableModalOpen.value = true
  startDurationTicker()
  scheduleSystemClock()
}

function setTableModalStatus(status: TableInfo['status']) {
  tableModalForm.value.status = status
}

function saveTableModal() {
  if (selectedTableForModal.value) {
    const orig = getTableByCode(selectedTableForModal.value.code)
    if (orig) {
      orig.status = tableModalForm.value.status
      orig.customerName = tableModalForm.value.customerName
      if (orig.status === 'Available') {
        orig.customerName = ''
        orig.billAmount = ''
        orig.occupiedDuration = ''
        orig.checkInTime = ''
      } else if (orig.status === 'Serving') {
        const now = new Date()
        orig.checkInTime = orig.checkInTime || now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
      }
    }
  }
  tableModalBaseline.value = { ...tableModalForm.value }
  isTableModalOpen.value = false
  selectedTableForModal.value = null
  stopDurationTicker()
  scheduleSystemClock()
}

async function closeTableModal() {
  if (await confirmTableDirty()) {
    isTableModalOpen.value = false
    selectedTableForModal.value = null
    stopDurationTicker()
  }
}

// ─── Modal 2: Create Booking ──────────────────────────────────────────────────
const isCreateBookingModalOpen = ref(false)
const isSubmittingBooking = ref(false)
const bookingErrors = reactive<Record<string, string>>({})
const newBookingForm = ref({ customerName: '', phone: '', guestCount: 4, reservationTime: '', assignedTable: '', notes: '' })

function openCreateBookingModal() {
  newBookingForm.value = { customerName: '', phone: '', guestCount: 4, reservationTime: '', assignedTable: '', notes: '' }
  Object.keys(bookingErrors).forEach(k => delete bookingErrors[k])
  isCreateBookingModalOpen.value = true
}

function setQuickBookingTime(minutes: number) {
  const now = new Date()
  now.setMinutes(now.getMinutes() + minutes)
  newBookingForm.value.reservationTime = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
}

function incrementGuests() { if (newBookingForm.value.guestCount < 50) newBookingForm.value.guestCount++ }
function decrementGuests() { if (newBookingForm.value.guestCount > 1) newBookingForm.value.guestCount-- }

function validateBookingForm(): boolean {
  Object.keys(bookingErrors).forEach(k => delete bookingErrors[k])
  const f = newBookingForm.value
  if (!f.customerName.trim()) bookingErrors.customerName = 'Vui lòng nhập tên khách hàng'
  const phoneClean = f.phone.replace(/\s/g, '')
  if (!phoneClean) bookingErrors.phone = 'Vui lòng nhập số điện thoại'
  else if (!/^(0|\+84)[3-9]\d{8}$/.test(phoneClean)) bookingErrors.phone = 'Số điện thoại không hợp lệ (VD: 0912345678)'
  if (!f.reservationTime) bookingErrors.reservationTime = 'Vui lòng chọn giờ khách đến'
  if (f.guestCount < 1 || f.guestCount > 50) bookingErrors.guestCount = 'Số khách phải từ 1 đến 50'
  return Object.keys(bookingErrors).length === 0
}

function saveNewBooking() {
  if (!validateBookingForm()) return
  isSubmittingBooking.value = true
  setTimeout(() => {
    const newId = 'b' + (bookings.value.length + 1)
    const newNumber = 'NC-' + new Date().toISOString().slice(0, 10).replace(/-/g, '') + '-' + String(bookings.value.length + 1).padStart(3, '0')
    const total = newBookingForm.value.guestCount
    const ad = Math.max(1, total - 1)
    const ch = Math.max(0, total - ad)
    const created: Booking = {
      id: newId,
      bookingNumber: newNumber,
      customerName: newBookingForm.value.customerName,
      phone: newBookingForm.value.phone,
      adults: ad,
      children: ch,
      reservationTime: newBookingForm.value.reservationTime,
      assignedTable: newBookingForm.value.assignedTable,
      notes: newBookingForm.value.notes,
      status: 'Waiting',
      date: getFormattedSelectedDate.value,
    }
    bookings.value.push(created)
    // Also push to receptionStore so it syncs to ReservationDetailView
    receptionAddReservation({
      customerName: created.customerName,
      customerPhone: created.phone,
      guests: created.adults,
      children: created.children,
      reservationDate: created.date,
      reservationTime: created.reservationTime,
      notes: created.notes,
      status: 'PENDING',
      source: 'Walk-in',
      tableCode: created.assignedTable || null,
      tableId: created.assignedTable || null,
      mealType: getBookingShift(created.reservationTime) === 'evening' ? 'DINNER' : 'LUNCH',
      isVip: false,
    })
    if (created.assignedTable) {
      const tbl = getTableByCode(created.assignedTable)
      if (tbl) { tbl.status = 'Reserved'; tbl.customerName = created.customerName }
    }
    isSubmittingBooking.value = false
    isCreateBookingModalOpen.value = false
  }, 600)
}

// ─── Modal 3: Quick Open (Walk-in) ────────────────────────────────────────────
const isQuickOpenModalOpen = ref(false)
const quickOpenForm = ref({ tableCode: '', customerName: '', guestCount: 2 })
const quickOpenBaseline = ref({ tableCode: '', customerName: '', guestCount: 2 })
const { confirmIfDirty: confirmQuickOpenDirty } = useUnsavedGuard(quickOpenForm, quickOpenBaseline)

function openQuickOpenModal() {
  quickOpenForm.value = { tableCode: '', customerName: t('admin_floors.table.walk_in'), guestCount: 2 }
  quickOpenBaseline.value = { ...quickOpenForm.value }
  isQuickOpenModalOpen.value = true
}

function goToOrderScreen(tableCode: string) {
  if (isTableModalOpen.value && selectedTableForModal.value && selectedTableForModal.value.code === tableCode) {
    tableModalForm.value.status = 'Serving'
    saveTableModal()
  }
  const tbl = getTableByCode(tableCode)
  if (tbl) {
    if (tbl.status !== 'Serving') {
      tbl.status = 'Serving'
      tbl.customerName = tbl.customerName || t('admin_floors.table.walk_in')
      tbl.billAmount = tbl.billAmount || '0đ'
      tbl.occupiedDuration = tbl.occupiedDuration || '1 phút'
      const now = new Date()
      tbl.checkInTime = tbl.checkInTime || now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
    }
    restaurantStore.setSelectedTable(tbl.code)
    router.push({ name: 'reception-order' })
  }
}

function saveQuickOpen() {
  if (!quickOpenForm.value.tableCode) {
    Swal.fire('Thông báo', 'Vui lòng chọn bàn cần mở.', 'info')
    return
  }
  const tbl = getTableByCode(quickOpenForm.value.tableCode)
  if (tbl) {
    tbl.status = 'Serving'
    tbl.customerName = quickOpenForm.value.customerName || t('admin_floors.table.walk_in')
    const now = new Date()
    tbl.checkInTime = now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
    goToOrderScreen(tbl.code)
  }
  quickOpenBaseline.value = { ...quickOpenForm.value }
  isQuickOpenModalOpen.value = false
}

// ─── Modal 4: Quick Check-in ──────────────────────────────────────────────────
const isQuickArrivedModalOpen = ref(false)
const quickArrivedForm = ref({ bookingId: '' })

function openQuickArrivedModal() {
  quickArrivedForm.value = { bookingId: '' }
  isQuickArrivedModalOpen.value = true
}

function saveQuickArrived() {
  if (!quickArrivedForm.value.bookingId) {
    Swal.fire('Thông báo', 'Vui lòng chọn khách hàng.', 'info')
    return
  }
  // Try legacy restaurantStore first
  const booking = bookings.value.find(b => b.id === quickArrivedForm.value.bookingId)
  if (booking) {
    booking.status = 'Arrived'
    if (booking.assignedTable) {
      const tbl = getTableByCode(booking.assignedTable)
      if (tbl) { tbl.status = 'Arrived'; tbl.customerName = booking.customerName }
    }
  } else {
    // Check receptionStore
    const receptionRes = receptionReservations.value.find(r => r.id === quickArrivedForm.value.bookingId)
    if (receptionRes) {
      receptionUpdateReservation(receptionRes.id, { status: 'CONFIRMED' })
      if (receptionRes.tableCode) {
        const tbl = getTableByCode(receptionRes.tableCode)
        if (tbl) { tbl.status = 'Arrived'; tbl.customerName = receptionRes.customerName }
      }
    }
  }
  isQuickArrivedModalOpen.value = false
}

// ─── Reset ─────────────────────────────────────────────────────────────────────
function resetToCurrentState() {
  selectedDate.value = new Date()
  currentYear.value = selectedDate.value.getFullYear()
  currentMonth.value = selectedDate.value.getMonth()
  selectedZone.value = 'All'
  activeShift.value = 'all'
  const now = new Date()
  const next = now.getHours() * 60 + now.getMinutes()
  timelineTime.value = next
  timelineTimeRaw.value = next
  conflictTables.value.clear()
}

// ─── Data Loading ──────────────────────────────────────────────────────────────
async function loadTables() {
  const { branchId } = useAuth()
  const bid = branchId.value
  if (!bid) return

  const { data: tablesData } = await supabase
    .from('tables')
    .select('id, code, capacity, status, metadata')
    .eq('branch_id', bid)
    .order('code', { ascending: true })

  if (tablesData && tablesData.length > 0) {
    const byZone = new Map<string, { name: string; tables: TableInfo[] }>()
    for (const tbl of tablesData as any[]) {
      const zoneName = tbl.metadata?.zone || 'Main'
      if (!byZone.has(zoneName)) byZone.set(zoneName, { name: zoneName, tables: [] })
      const uiStatus: TableInfo['status'] =
        tbl.status === 'available' ? 'Available'
        : tbl.status === 'reserved' ? 'Reserved'
        : tbl.status === 'occupied' ? 'Serving'
        : tbl.status === 'maintenance' ? 'Maintenance'
        : 'Available'
      byZone.get(zoneName)!.tables.push({
        id: tbl.id,
        code: tbl.code,
        status: uiStatus,
        capacity: tbl.capacity,
        metadata: tbl.metadata || {},
      })
    }
    areas.value = Array.from(byZone.values())
      .sort((a, b) => a.name.localeCompare(b.name, 'vi'))
      .map<AreaInfo>(z => ({ name: z.name, description: z.name, tables: z.tables }))
  }
}

// ─── Lifecycle ─────────────────────────────────────────────────────────────────
onMounted(async () => {
  updateSystemClock()
  scheduleSystemClock()
  resetTimeline()

  const { session, branchId } = useAuth()
  if (session.value) {
    const bid = branchId.value
    if (bid) {
      await loadTables()
      // Load reservations from receptionStore (shared with ReservationDetailView)
      // This picks up Supabase data, localStorage cache, or mock data automatically
      await loadReceptionReservations()
      const { data: resData } = await supabase.from('reservations').select('*, customers(name, phone)').eq('branch_id', bid)
      if (resData) {
        bookings.value = resData.map((r: any) => ({
          id: r.id,
          bookingNumber: r.booking_code,
          customerName: r.customers?.name || 'Khách',
          phone: r.customers?.phone || '',
          adults: r.guests || 0,
          children: r.children_count || 0,
          reservationTime: r.reservation_time,
          assignedTable: r.table_id || '',
          notes: (r.booking_info as any)?.notes || '',
          status: r.status === 'PENDING' ? 'Waiting' : r.status === 'CONFIRMED' ? 'Waiting' : r.status === 'CHECKED_IN' ? 'Arrived' : r.status === 'SEATED' ? 'Seated' : r.status === 'COMPLETED' ? 'Completed' : 'Cancelled',
          date: r.reservation_date,
        }))
      }
      checkConflicts()
    }
  }
})

onUnmounted(() => {
  if (systemClockInterval) clearInterval(systemClockInterval)
  stopDurationTicker()
  if (timelineDebounce != null) { clearTimeout(timelineDebounce); timelineDebounce = null }
})
</script>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.2s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes fadeIn {
  from { opacity: 0; transform: scale(0.96); }
  to { opacity: 1; transform: scale(1); }
}

.custom-scrollbar::-webkit-scrollbar {
  width: 5px;
  height: 5px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: #cbd5e1;
  border-radius: 20px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background-color: #94a3b8;
}

.scrollbar-none::-webkit-scrollbar {
  display: none;
}

@keyframes shake {
  0%, 100% { transform: translateX(0); }
  10%, 30%, 50%, 70%, 90% { transform: translateX(-4px); }
  20%, 40%, 60%, 80% { transform: translateX(4px); }
}
.animate-shake {
  animation: shake 0.4s cubic-bezier(.36,.07,.19,.97) both;
}
</style>
