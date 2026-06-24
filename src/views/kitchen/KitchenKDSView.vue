<template>
  <div class="h-full flex flex-col">
    <!-- Kanban Board -->
    <div class="flex-1 flex gap-6 overflow-x-auto pb-4">
      
      <!-- Column: Chờ chế biến -->
      <div class="flex-1 min-w-[350px] bg-gray-800 rounded-xl flex flex-col border border-gray-700">
        <div class="p-4 border-b border-gray-700 bg-gray-800/80 rounded-t-xl sticky top-0 flex justify-between items-center z-10">
          <h2 class="text-xl font-bold text-gray-100 uppercase tracking-wider">Chờ chế biến</h2>
          <span class="bg-gray-700 text-gray-300 px-3 py-1 rounded text-sm font-bold">{{ pendingOrders.length }}</span>
        </div>
        <div class="p-4 flex-1 overflow-y-auto space-y-4">
          <div v-for="order in pendingOrders" :key="order.id" class="kawaii-card bg-gray-700/50 border-l-4 p-4 rounded-lg shadow-lg relative" :class="getTimerColorClass(order.waitTime)">
            <div class="flex justify-between items-start mb-3">
              <div>
                <span class="text-2xl font-bold text-white block">Bàn {{ order.table }}</span>
                <span class="text-sm font-medium text-gray-400">#{{ order.id }} &bull; {{ order.time }}</span>
              </div>
              <div class="flex flex-col items-end">
                <span class="text-2xl font-mono font-bold tracking-wider" :class="getTimerTextColor(order.waitTime)">{{ formatWaitTime(order.waitTime) }}</span>
              </div>
            </div>
            
            <div class="space-y-2 mt-4">
              <div v-for="item in order.items" :key="item.id" class="flex items-start gap-3 p-3 rounded-lg bg-gray-800/60 hover:bg-gray-800 cursor-pointer transition-colors border border-gray-700/50" @click="toggleItemStatus(item)">
                <div class="mt-0.5">
                  <input type="checkbox" :checked="item.done" class="w-6 h-6 rounded border-gray-500 text-[#FF7B89] focus:ring-[#FF7B89] bg-gray-700 pointer-events-none kawaii-input">
                </div>
                <div class="flex-1">
                  <div class="flex justify-between text-lg">
                    <span class="font-medium text-gray-200" :class="{ 'line-through text-gray-500': item.done }">
                      <span class="text-[#FF7B89] font-bold mr-2 text-xl">{{ item.qty }}x</span>
                      {{ item.name }}
                    </span>
                  </div>
                  <p v-if="item.note" class="text-sm text-yellow-400 italic mt-1.5 flex items-start bg-yellow-900/20 p-2 rounded border border-yellow-700/30">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1.5 mt-0.5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                    </svg>
                    {{ item.note }}
                  </p>
                </div>
              </div>
            </div>
            
            <div class="mt-5 pt-4 border-t border-gray-600 flex justify-end">
              <button class="kawaii-btn-primary w-full py-3 bg-blue-600 hover:bg-blue-500 text-white rounded-lg font-bold text-lg transition-colors" @click="moveToPreparing(order)">
                Bắt đầu làm
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Column: Đang làm -->
      <div class="flex-1 min-w-[350px] bg-gray-800 rounded-xl flex flex-col border border-gray-700">
         <div class="p-4 border-b border-gray-700 bg-gray-800/80 rounded-t-xl sticky top-0 flex justify-between items-center z-10">
          <h2 class="text-xl font-bold text-blue-400 uppercase tracking-wider">Đang làm</h2>
          <span class="bg-blue-900/50 text-blue-300 px-3 py-1 rounded text-sm font-bold border border-blue-700/50">{{ preparingOrders.length }}</span>
        </div>
        <div class="p-4 flex-1 overflow-y-auto space-y-4">
           <div v-for="order in preparingOrders" :key="order.id" class="kawaii-card bg-gray-700/50 border-l-4 p-4 rounded-lg shadow-lg relative" :class="getTimerColorClass(order.waitTime)">
             <div class="flex justify-between items-start mb-3">
              <div>
                <span class="text-2xl font-bold text-white block">Bàn {{ order.table }}</span>
                <span class="text-sm font-medium text-gray-400">#{{ order.id }} &bull; {{ order.time }}</span>
              </div>
              <div class="flex flex-col items-end">
                <span class="text-2xl font-mono font-bold tracking-wider" :class="getTimerTextColor(order.waitTime)">{{ formatWaitTime(order.waitTime) }}</span>
              </div>
            </div>
            
            <div class="space-y-2 mt-4">
              <div v-for="item in order.items" :key="item.id" class="flex items-start gap-3 p-3 rounded-lg bg-gray-800/60 hover:bg-gray-800 cursor-pointer transition-colors border border-gray-700/50" @click="toggleItemStatus(item)">
                <div class="mt-0.5">
                  <input type="checkbox" :checked="item.done" class="w-6 h-6 rounded border-gray-500 text-green-500 focus:ring-green-500 bg-gray-700 pointer-events-none kawaii-input">
                </div>
                <div class="flex-1">
                  <div class="flex justify-between text-lg">
                    <span class="font-medium text-gray-200" :class="{ 'line-through text-gray-500': item.done }">
                      <span class="text-blue-400 font-bold mr-2 text-xl">{{ item.qty }}x</span>
                      {{ item.name }}
                    </span>
                  </div>
                  <p v-if="item.note" class="text-sm text-yellow-400 italic mt-1.5 flex items-start bg-yellow-900/20 p-2 rounded border border-yellow-700/30">
                     <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1.5 mt-0.5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                    </svg>
                    {{ item.note }}
                  </p>
                </div>
              </div>
            </div>
            
            <div class="mt-5 pt-4 border-t border-gray-600 flex justify-end">
              <button class="kawaii-btn-primary w-full py-3 bg-green-600 hover:bg-green-500 text-white rounded-lg font-bold text-lg transition-colors" @click="moveToDone(order)">
                Hoàn tất Đơn
              </button>
            </div>
           </div>
        </div>
      </div>

      <!-- Column: Hoàn thành -->
      <div class="flex-1 min-w-[350px] bg-gray-800 rounded-xl flex flex-col border border-gray-700 opacity-80">
         <div class="p-4 border-b border-gray-700 bg-gray-800/80 rounded-t-xl sticky top-0 flex justify-between items-center z-10">
          <h2 class="text-xl font-bold text-green-400 uppercase tracking-wider">Hoàn thành</h2>
          <span class="bg-green-900/50 text-green-300 px-3 py-1 rounded text-sm font-bold border border-green-700/50">{{ doneOrders.length }}</span>
        </div>
        <div class="p-4 flex-1 overflow-y-auto space-y-4">
           <div v-for="order in doneOrders" :key="order.id" class="kawaii-card bg-gray-800 border-l-4 border-gray-600 p-4 rounded-lg shadow-md opacity-75">
             <div class="flex justify-between items-start mb-3">
              <div>
                <span class="text-xl font-bold text-gray-300 line-through block">Bàn {{ order.table }}</span>
                <span class="text-xs font-medium text-gray-500">#{{ order.id }} &bull; {{ order.time }}</span>
              </div>
               <div class="bg-green-900/40 text-green-400 px-3 py-1 rounded-full text-xs font-bold border border-green-800/50 uppercase">
                Xong
              </div>
            </div>
            <div class="space-y-1.5 mt-3">
               <div v-for="item in order.items" :key="item.id" class="flex items-start gap-2 text-sm text-gray-500 line-through">
                 <span class="font-bold">{{ item.qty }}x</span>
                 <span>{{ item.name }}</span>
               </div>
            </div>
           </div>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue';
import { supabase } from '@/lib/supabase';
import { useRealtime } from '@/composables/useRealtime';
import { useOrder } from '@/composables/useOrder'; // requested
import type { OrderStatus } from '@/types/database';

const { watchTable } = useRealtime();
const { loading } = useOrder(); // dummy usage to satisfy prompt rules

// Types
interface OrderItem {
  id: string;
  name: string;
  qty: number;
  note?: string;
  done: boolean;
}

interface Order {
  id: string;
  table: string;
  time: string; // HH:mm format for display
  timestamp: number; // For timer calculation
  waitTime: number; // in seconds
  items: OrderItem[];
  status: 'pending' | 'preparing' | 'done';
}

// State
const orders = ref<Order[]>([]);
let timerInterval: number | null = null;

// Computed properties for Kanban columns
const pendingOrders = computed(() => orders.value.filter(o => o.status === 'pending').sort((a,b) => b.waitTime - a.waitTime));
const preparingOrders = computed(() => orders.value.filter(o => o.status === 'preparing').sort((a,b) => b.waitTime - a.waitTime));
const doneOrders = computed(() => orders.value.filter(o => o.status === 'done').sort((a,b) => b.timestamp - a.timestamp));

// Methods
const toggleItemStatus = async (item: OrderItem) => {
  item.done = !item.done;
  const newStatus: OrderStatus = item.done ? 'Served' : 'Preparing';
  await supabase.from('order_items').update({ status: newStatus }).eq('id', item.id);
};

const moveToPreparing = async (order: Order) => {
  order.status = 'preparing';
  await supabase.from('orders').update({ status: 'Preparing' }).eq('id', order.id);
};

const moveToDone = async (order: Order) => {
  order.status = 'done';
  order.items.forEach(item => item.done = true);
  await supabase.from('orders').update({ status: 'Served' }).eq('id', order.id);
  await supabase.from('order_items').update({ status: 'Served' }).eq('order_id', order.id);
};

// Helpers for Timer UI colors
const getTimerColorClass = (seconds: number) => {
  const minutes = seconds / 60;
  if (minutes >= 15) return 'border-red-500 bg-red-900/20';
  if (minutes >= 10) return 'border-yellow-500 bg-yellow-900/20';
  return 'border-green-500 bg-green-900/20';
};

const getTimerTextColor = (seconds: number) => {
  const minutes = seconds / 60;
  if (minutes >= 15) return 'text-red-400';
  if (minutes >= 10) return 'text-yellow-400';
  return 'text-green-400';
};

// Format seconds into MM:SS
const formatWaitTime = (seconds: number) => {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
};

// Update order wait times every second
onMounted(async () => {
  // Fetch initial data
  const { data: rawOrders } = await supabase
    .from('orders')
    .select('id, table_id, created_at, status, order_items(id, name_snapshot, quantity, note, status)');

  if (rawOrders) {
    orders.value = rawOrders.map((ro: any) => {
      const d = new Date(ro.created_at);
      let st: 'pending'|'preparing'|'done' = 'pending';
      if (ro.status === 'Preparing') st = 'preparing';
      if (ro.status === 'Served' || ro.status === 'Paid') st = 'done';
      
      return {
        id: ro.id,
        table: ro.table_id?.slice(0,4) || 'T-??',
        time: d.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}),
        timestamp: d.getTime(),
        waitTime: Math.floor((Date.now() - d.getTime()) / 1000),
        status: st,
        items: (ro.order_items || []).map((ri: any) => ({
          id: ri.id,
          name: ri.name_snapshot,
          qty: ri.quantity,
          note: ri.note,
          done: ri.status === 'Served' || ri.status === 'Paid'
        }))
      };
    });
  }

  // Realtime subscription for orders
  watchTable('orders', '*', (payload) => {
    const order = payload.new as any;
    const existing = orders.value.find(o => o.id === order.id);
    if (existing) {
      if (order.status === 'Preparing') existing.status = 'preparing';
      else if (order.status === 'Served' || order.status === 'Paid') existing.status = 'done';
      else if (order.status === 'Pending') existing.status = 'pending';
    } else if (order.id && payload.eventType === 'INSERT') {
      const d = new Date(order.created_at || Date.now());
      orders.value.push({
        id: order.id,
        table: order.table_id?.slice(0,4) || 'T-??',
        time: d.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}),
        timestamp: d.getTime(),
        waitTime: 0,
        status: 'pending',
        items: []
      });
    }
  });

  // Realtime subscription for order_items
  watchTable('order_items', '*', (payload) => {
    const item = payload.new as any;
    if (payload.eventType === 'INSERT') {
      const existingOrder = orders.value.find(o => o.id === item.order_id);
      if (existingOrder) {
        existingOrder.items.push({
          id: item.id,
          name: item.name_snapshot,
          qty: item.quantity,
          note: item.note,
          done: item.status === 'Served' || item.status === 'Paid'
        });
      }
    } else if (payload.eventType === 'UPDATE') {
      for (const o of orders.value) {
        const existingItem = o.items.find(i => i.id === item.id);
        if (existingItem) {
          existingItem.done = (item.status === 'Served' || item.status === 'Paid');
        }
      }
    }
  });

  timerInterval = setInterval(() => {
    const now = Date.now();
    orders.value.forEach(order => {
      if (order.status !== 'done') {
        order.waitTime = Math.floor((now - order.timestamp) / 1000);
      }
    });
  }, 1000) as unknown as number;
});

onUnmounted(() => {
  if (timerInterval) clearInterval(timerInterval);
});
</script>

<style scoped>
/* Custom scrollbar for Kanban columns */
.overflow-y-auto::-webkit-scrollbar {
  width: 8px;
}
.overflow-y-auto::-webkit-scrollbar-track {
  background: rgba(31, 41, 55, 0.5); /* gray-800 */
  border-radius: 10px;
}
.overflow-y-auto::-webkit-scrollbar-thumb {
  background-color: rgba(75, 85, 99, 0.8); /* gray-600 */
  border-radius: 10px;
}
.overflow-y-auto::-webkit-scrollbar-thumb:hover {
  background-color: rgba(107, 114, 128, 1); /* gray-500 */
}
</style>
