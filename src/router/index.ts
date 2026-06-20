import { createRouter, createWebHistory } from 'vue-router'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import TimelineView from '@/views/TimelineView.vue'
import ListView from '@/views/ListView.vue'
import FloorPlanView from '@/views/FloorPlanView.vue'
import OrderDetailView from '@/views/OrderDetailView.vue'

const routes = [
  {
    path: '/',
    component: DashboardLayout,
    children: [
      {
        path: '',
        name: 'timeline',
        component: TimelineView,
      },
      {
        path: 'list',
        name: 'list',
        component: ListView,
      },
      {
        path: 'floor-plan',
        name: 'floor-plan',
        component: FloorPlanView,
      },
      {
        path: 'order/:id',
        name: 'order-detail',
        component: OrderDetailView,
      },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
