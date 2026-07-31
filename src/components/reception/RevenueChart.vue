<!--
  RevenueChart.vue
  ─────────────────────────────────────────────────────────────────────────────
  Standalone Chart.js line chart for the 7-day revenue display on the
  Reception Dashboard.  Receives data via props — no store/API coupling.
-->
<template>
  <div class="relative h-64">
    <canvas ref="canvasRef"></canvas>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { Chart, registerables } from 'chart.js'
import { TrendingUp } from 'lucide-vue-next'
import type { DashboardRevenuePoint } from '@/data/dashboardMockData'

Chart.register(...registerables)

const props = defineProps<{
  data: DashboardRevenuePoint[]
}>()

const canvasRef = ref<HTMLCanvasElement | null>(null)
let chartInstance: Chart | null = null

function initChart() {
  if (!canvasRef.value) return
  if (chartInstance) chartInstance.destroy()

  const labels = props.data.map((d) =>
    new Date(d.date).toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' }),
  )
  const revenueData = props.data.map((d) => d.revenue)

  chartInstance = new Chart(canvasRef.value, {
    type: 'line',
    data: {
      labels,
      datasets: [
        {
          label: 'Doanh thu (đ)',
          data: revenueData,
          borderColor: '#E8772E',
          backgroundColor: 'rgba(232,119,46,0.08)',
          borderWidth: 2,
          fill: true,
          tension: 0.35,
          pointBackgroundColor: '#E8772E',
          pointBorderColor: '#fff',
          pointBorderWidth: 1.5,
          pointRadius: 4,
          pointHoverRadius: 6,
        },
      ],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: (ctx) =>
              `${ctx.dataset.label}: ${Number(ctx.parsed.y).toLocaleString('vi-VN')}đ`,
          },
        },
      },
      scales: {
        x: {
          grid: { display: false },
          ticks: { font: { size: 10 }, color: '#9ca3af' },
        },
        y: {
          grid: { color: '#f3f4f6' },
          ticks: {
            font: { size: 10 },
            color: '#9ca3af',
            callback: (v) =>
              Number(v) >= 1_000_000
                ? `${Math.round(Number(v) / 1_000_000)}tr`
                : Number(v).toLocaleString('vi-VN'),
          },
        },
      },
    },
  })
}

onMounted(() => {
  nextTick(() => initChart())
})

watch(
  () => props.data,
  () => {
    nextTick(() => initChart())
  },
  { deep: true },
)

onUnmounted(() => {
  if (chartInstance) {
    chartInstance.destroy()
    chartInstance = null
  }
})
</script>
