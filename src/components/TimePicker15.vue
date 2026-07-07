<template>
  <div class="space-y-1.5">
    <!-- Selected value header -->
    <div class="flex items-center justify-between">
      <span class="text-[10px] font-extrabold uppercase tracking-wider text-gray-400">
        {{ label || 'Giờ (snap 15 phút)' }}
      </span>
      <span
        class="px-2 py-0.5 rounded-md text-xs font-mono font-extrabold text-rose-700 bg-rose-50 border border-rose-200"
        :title="titleFormat"
      >
        {{ modelValue || '--:--' }}
      </span>
    </div>

    <!-- Chip grid: minHour → maxHour in 15-minute steps.
         Past-time chips (value < minTime) are disabled and greyed. -->
    <div
      class="grid grid-cols-6 sm:grid-cols-8 gap-1.5 p-2 max-h-48 overflow-y-auto rounded-xl border border-gray-200 bg-gray-50/40"
    >
      <button
        v-for="slot in slots"
        :key="slot.value"
        type="button"
        :disabled="slot.isPast"
        class="px-1.5 py-1.5 rounded-lg text-[11px] font-extrabold border transition-fast select-none focus:outline-none"
        :class="
          slot.isPast
            ? 'bg-gray-100 border-gray-200 text-gray-300 cursor-not-allowed line-through'
            : slot.value === modelValue
              ? 'bg-rose-500 border-rose-600 text-white shadow-sm'
              : 'bg-white border-gray-200 text-gray-700 hover:bg-rose-50 hover:border-rose-200'
        "
        :title="slot.isPast ? 'Đã qua' : `Chọn ${slot.value}`"
        @click="selectSlot(slot.value)"
        @dblclick="selectSlot(slot.value); $emit('confirm')"
      >
        {{ slot.label }}
      </button>
    </div>

    <!-- Quick helpers: now / +15min / +1h (each clamps to minTime) -->
    <div class="flex items-center gap-1.5">
      <button
        v-for="h in helpers"
        :key="h.label"
        type="button"
        class="px-2 py-1 rounded-md text-[10px] font-bold border border-gray-200 bg-white text-gray-600 hover:bg-gray-100 transition-fast"
        @click="selectSlot(h.value)"
      >
        {{ h.label }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'

const props = withDefaults(
  defineProps<{
    /** Selected "HH:mm" value. */
    modelValue: string
    /** Earliest selectable hour (24h). Default 6 = 06:00. */
    minHour?: number
    /** Latest selectable hour (24h). Default 23 (last slot is 23:45). */
    maxHour?: number
    /**
     * Floor "HH:mm" — chips earlier than this are disabled. Auto-refreshes
     * from now() every minute while the picker is mounted so the chip grid
     * stays accurate over long sessions (e.g. an open booking modal).
     */
    minTime?: string
    /** Optional label. */
    label?: string
  }>(),
  {
    minHour: 6,
    maxHour: 23,
    minTime: '',
    label: '',
  },
)

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
  (e: 'confirm'): void
}>()

interface Slot {
  value: string // "HH:mm"
  label: string // "HH:mm"
  isPast: boolean
}

// Auto-refresh "now" once a minute so the disabled-past state stays correct
// when the picker stays open across a 15-minute boundary.
const nowTick = ref(Date.now())
let tickHandle: number | null = null
onMounted(() => {
  tickHandle = window.setInterval(() => {
    nowTick.value = Date.now()
  }, 60_000)
})
onBeforeUnmount(() => {
  if (tickHandle != null) {
    window.clearInterval(tickHandle)
    tickHandle = null
  }
})

/** Returns "HH:mm" for the current "now". */
function nowHHmm(): string {
  const d = new Date(nowTick.value)
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
}

/** Effective minTime — explicit prop, else auto "now rounded UP to next 15-min". */
function effectiveMinTime(): string {
  if (props.minTime && props.minTime.trim()) return props.minTime
  // Auto: next 15-min boundary from now.
  const d = new Date(nowTick.value)
  const ms = 1000 * 60 * 15
  const rounded = new Date(Math.ceil(d.getTime() / ms) * ms)
  return `${String(rounded.getHours()).padStart(2, '0')}:${String(rounded.getMinutes()).padStart(2, '0')}`
}

function timeToMinutes(t: string): number {
  const [h, m] = t.split(':').map(Number)
  return (h ?? 0) * 60 + (m ?? 0)
}

const slots = computed<Slot[]>(() => {
  const minMinutes = timeToMinutes(effectiveMinTime())
  const out: Slot[] = []
  for (let h = props.minHour; h <= props.maxHour; h++) {
    for (const m of [0, 15, 30, 45]) {
      const hh = String(h).padStart(2, '0')
      const mm = String(m).padStart(2, '0')
      const value = `${hh}:${mm}`
      const slotMinutes = h * 60 + m
      out.push({ value, label: value, isPast: slotMinutes < minMinutes })
    }
  }
  return out
})

function selectSlot(value: string) {
  // Defensive: never emit a past-time value even if a button slips through.
  const minMinutes = timeToMinutes(effectiveMinTime())
  const [h, m] = value.split(':').map(Number)
  if (h * 60 + m < minMinutes) return
  emit('update:modelValue', value)
}

const helpers = computed(() => {
  const d = new Date(nowTick.value)
  const roundToQuarter = (dt: Date) => {
    const ms = 1000 * 60 * 15
    return new Date(Math.ceil(dt.getTime() / ms) * ms)
  }
  const fmt = (dt: Date) =>
    `${String(dt.getHours()).padStart(2, '0')}:${String(dt.getMinutes()).padStart(2, '0')}`
  const nowQ = roundToQuarter(d)
  const plus15 = new Date(nowQ.getTime() + 15 * 60 * 1000)
  const plus60 = new Date(nowQ.getTime() + 60 * 60 * 1000)
  return [
    { label: 'Hiện tại', value: fmt(nowQ) },
    { label: '+15 phút', value: fmt(plus15) },
    { label: '+1 giờ', value: fmt(plus60) },
  ]
})

const titleFormat = computed(() => {
  if (!props.modelValue) return 'Chưa chọn'
  return `Đã chọn ${props.modelValue}`
})
</script>