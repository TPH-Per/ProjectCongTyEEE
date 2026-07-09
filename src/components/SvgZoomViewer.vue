<template>
  <div class="svg-viewer-wrapper h-full w-full relative flex flex-col bg-white">
    <!-- Toolbar -->
    <div class="absolute top-4 right-4 z-10 flex gap-2">
      <button @click="resetZoom" class="p-2 bg-white rounded-lg shadow-sm border border-slate-200 hover:bg-slate-50 transition-colors" title="Reset Zoom">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 text-slate-600" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4" />
        </svg>
      </button>
      <button @click="zoomIn" class="p-2 bg-white rounded-lg shadow-sm border border-slate-200 hover:bg-slate-50 transition-colors" title="Zoom In">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 text-slate-600" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7" />
        </svg>
      </button>
      <button @click="zoomOut" class="p-2 bg-white rounded-lg shadow-sm border border-slate-200 hover:bg-slate-50 transition-colors" title="Zoom Out">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 text-slate-600" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM13 10H7" />
        </svg>
      </button>
    </div>

    <!-- Container -->
    <div 
      ref="containerRef"
      class="svg-container flex-1 overflow-hidden cursor-grab active:cursor-grabbing w-full h-full min-h-[600px] flex items-center justify-center bg-slate-50/50"
      v-html="svgContent"
    ></div>
    
    <!-- Loading state -->
    <div v-if="loading" class="absolute inset-0 flex items-center justify-center bg-white/80 z-20">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch, nextTick } from 'vue'
import * as d3 from 'd3'

const props = defineProps<{
  src: string
}>()

const containerRef = ref<HTMLElement | null>(null)
const svgContent = ref<string>('')
const loading = ref(false)

let zoomBehavior: any = null
let svgSelection: any = null

const loadSvg = async () => {
  if (!props.src) return
  loading.value = true
  try {
    const response = await fetch(props.src)
    if (!response.ok) throw new Error('Failed to fetch SVG')
    const text = await response.text()
    svgContent.value = text
    await nextTick()
    initZoom()
  } catch (error) {
    console.error('Error loading SVG:', error)
  } finally {
    loading.value = false
  }
}

const initZoom = () => {
  if (!containerRef.value) return

  const svgEl = containerRef.value.querySelector('svg')
  if (!svgEl) return

  svgSelection = d3.select(svgEl)
  const container = d3.select(containerRef.value)

  container.on('.zoom', null)

  svgSelection.attr('width', '100%').attr('height', '100%')
  
  const existingWrapper = svgSelection.select('g.d3-zoom-wrapper')
  let zoomTarget: d3.Selection<SVGGElement, unknown, null, undefined>

  if (existingWrapper.empty()) {
    const children = Array.from(svgEl.childNodes)
    const wrapper = document.createElementNS('http://www.w3.org/2000/svg', 'g')
    wrapper.setAttribute('class', 'd3-zoom-wrapper')
    
    children.forEach(child => {
      wrapper.appendChild(child)
    })
    svgEl.appendChild(wrapper)
    zoomTarget = d3.select(wrapper) as any
  } else {
    zoomTarget = existingWrapper as any
  }

  zoomBehavior = d3.zoom()
    .scaleExtent([0.1, 10])
    .on('zoom', (event) => {
      zoomTarget.attr('transform', event.transform)
    })

  container.call(zoomBehavior as any)

  setTimeout(() => {
    fitToContainer()
  }, 100)
}

const fitToContainer = () => {
  if (!containerRef.value || !svgSelection || !zoomBehavior) return

  const containerBounds = containerRef.value.getBoundingClientRect()
  if (containerBounds.width === 0 || containerBounds.height === 0) {
    setTimeout(fitToContainer, 100)
    return
  }

  const viewBoxAttr = svgSelection.attr('viewBox')
  
  let naturalWidth = 1000
  let naturalHeight = 1000
  
  if (viewBoxAttr) {
    const parts = viewBoxAttr.split(/\s+|,/)
    if (parts.length === 4) {
      naturalWidth = parseFloat(parts[2])
      naturalHeight = parseFloat(parts[3])
    }
  }

  const padding = 20
  const scale = (containerBounds.width - padding * 2) / naturalWidth

  const tx = (containerBounds.width - naturalWidth * scale) / 2
  const scaledHeight = naturalHeight * scale
  const ty = scaledHeight < containerBounds.height 
    ? (containerBounds.height - scaledHeight) / 2 
    : padding

  const initialTransform = d3.zoomIdentity.translate(tx, ty).scale(scale)
  
  zoomBehavior.scaleExtent([scale, scale * 10])

  d3.select(containerRef.value)
    .transition()
    .duration(750)
    .call(zoomBehavior.transform as any, initialTransform)
}

const resetZoom = () => {
  fitToContainer()
}

const zoomIn = () => {
  if (!containerRef.value || !zoomBehavior) return
  d3.select(containerRef.value)
    .transition()
    .duration(300)
    .call(zoomBehavior.scaleBy as any, 1.3)
}

const zoomOut = () => {
  if (!containerRef.value || !zoomBehavior) return
  d3.select(containerRef.value)
    .transition()
    .duration(300)
    .call(zoomBehavior.scaleBy as any, 0.7)
}

onMounted(() => {
  loadSvg()
})

watch(() => props.src, () => {
  loadSvg()
})
</script>

<style scoped>
.svg-container :deep(svg) {
  display: block;
}
</style>
