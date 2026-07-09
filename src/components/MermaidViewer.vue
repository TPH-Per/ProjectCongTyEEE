<template>
  <div class="relative w-full h-full border border-gray-200 rounded-xl overflow-hidden bg-white shadow-sm flex flex-col">
    <div class="absolute top-4 right-4 z-10 flex gap-2">
      <button @click="resetZoom" class="p-2 bg-white rounded-lg shadow-sm border border-gray-200 hover:bg-gray-50 text-gray-600 transition-colors" title="Fit to Screen">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg>
      </button>
      <button @click="zoomIn" class="p-2 bg-white rounded-lg shadow-sm border border-gray-200 hover:bg-gray-50 text-gray-600 transition-colors" title="Zoom In">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line><line x1="11" y1="8" x2="11" y2="14"></line><line x1="8" y1="11" x2="14" y2="11"></line></svg>
      </button>
      <button @click="zoomOut" class="p-2 bg-white rounded-lg shadow-sm border border-gray-200 hover:bg-gray-50 text-gray-600 transition-colors" title="Zoom Out">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line><line x1="8" y1="11" x2="14" y2="11"></line></svg>
      </button>
    </div>
    <div 
      ref="container" 
      class="flex-1 w-full h-full min-h-[500px] cursor-grab active:cursor-grabbing overflow-hidden relative"
      @click="handleNodeClick"
    >
      <div v-html="svgContent" class="mermaid-diagram-wrapper absolute inset-0 w-full h-full"></div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick } from 'vue'
import mermaid from 'mermaid'
import * as d3 from 'd3-selection'
import * as d3Zoom from 'd3-zoom'

const props = defineProps<{
  id: string
  code: string
}>()

const emit = defineEmits<{
  (e: 'node-click', nodeId: string): void
}>()

const container = ref<HTMLElement | null>(null)
const svgContent = ref<string>('')
let zoomBehavior: d3Zoom.ZoomBehavior<Element, unknown> | null = null
let svgSelection: d3.Selection<Element, unknown, null, undefined> | null = null
let initialTransform: d3Zoom.ZoomTransform | null = null

// Initialize mermaid
mermaid.initialize({
  startOnLoad: false,
  theme: 'default',
  securityLevel: 'loose',
  fontFamily: 'Inter, sans-serif'
})

async function renderDiagram() {
  if (!props.code) return
  
  try {
    const { svg } = await mermaid.render(`mermaid-svg-${props.id}`, props.code)
    svgContent.value = svg
    
    await nextTick()
    setupZoom()
  } catch (err) {
    console.error('Mermaid render error:', err)
    svgContent.value = `<div class="p-4 text-red-500">Error rendering diagram</div>`
  }
}

function setupZoom() {
  if (!container.value) return
  
  const svgElement = container.value.querySelector('svg')
  if (!svgElement) return
  
  // Remove hardcoded dimensions and viewBox so D3 zoom can completely control the view
  svgElement.removeAttribute('width')
  svgElement.removeAttribute('height')
  svgElement.removeAttribute('viewBox')
  svgElement.style.width = '100%'
  svgElement.style.height = '100%'
  
  svgSelection = d3.select(svgElement) as any
  
  let inner = svgSelection!.select('g')
  if (inner.empty()) {
    // If no group found, we can't properly apply d3 zoom
    return
  }

  // Calculate fit-to-screen scale and translation
  const innerNode = inner.node() as SVGGElement
  const bbox = innerNode.getBBox()
  
  const rect = container.value.getBoundingClientRect()
  const width = rect.width
  const height = rect.height
  
  const padding = 60
  // prevent divide by zero
  if (bbox.width === 0 || bbox.height === 0) return

  const scale = Math.min((width - padding) / bbox.width, (height - padding) / bbox.height, 2)
  const x = (width - bbox.width * scale) / 2 - bbox.x * scale
  const y = (height - bbox.height * scale) / 2 - bbox.y * scale
  
  initialTransform = d3Zoom.zoomIdentity.translate(x, y).scale(scale)

  zoomBehavior = d3Zoom.zoom()
    .scaleExtent([0.1, 10])
    .on('zoom', (e) => {
      inner.attr('transform', e.transform)
    })

  svgSelection!.call(zoomBehavior as any)
  
  // Instantly apply initial transform to center the diagram
  svgSelection!.call(zoomBehavior!.transform as any, initialTransform)
}

function zoomIn() {
  if (svgSelection && zoomBehavior) {
    zoomBehavior.scaleBy(svgSelection.transition().duration(250) as any, 1.3)
  }
}

function zoomOut() {
  if (svgSelection && zoomBehavior) {
    zoomBehavior.scaleBy(svgSelection.transition().duration(250) as any, 1 / 1.3)
  }
}

function resetZoom() {
  if (svgSelection && zoomBehavior && initialTransform) {
    svgSelection.transition().duration(500).call(zoomBehavior.transform as any, initialTransform)
  }
}

function handleNodeClick(e: MouseEvent) {
  const target = e.target as Element
  
  let current: Element | null = target
  while (current && current !== e.currentTarget) {
    // Check ID
    if (current.id) {
      let id = current.id
      const match = id.match(/^(?:flowchart|mindmap-node)-(.*?)(?:-\d+)?$/)
      if (match && match[1]) {
        id = match[1]
      }
      
      // If we found a valid looking node_ prefix, emit it
      if (id.includes('node_')) {
        emit('node-click', id)
        return
      }
    }
    
    // Fallback: Check text content for mindmap nodes that might not have proper IDs
    if (current.tagName.toLowerCase() === 'g' || current.tagName.toLowerCase() === 'text') {
      const text = current.textContent || ''
      if (text.includes('CRM - Quản lý') || text.includes('CRM -')) {
        emit('node-click', 'node_crm')
        return
      }
    }
    
    current = current.parentElement
  }
}

watch(() => props.code, renderDiagram, { immediate: true })
</script>

<style>
.mermaid-diagram-wrapper svg {
  display: block;
  width: 100%;
  height: 100%;
}
.node {
  cursor: pointer;
  transition: opacity 0.2s;
}
.node:hover {
  opacity: 0.8;
}
</style>
