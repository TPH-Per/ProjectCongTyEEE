import type { RouteRecordRaw } from 'vue-router'
import HallDashboard from '@/views/hall/HallDashboard.vue'

const hallRoutes: RouteRecordRaw[] = [
  {
    path: '/hall',
    name: 'hall.dashboard',
    component: HallDashboard,
    meta: {
      requiresAuth: true,
      role: 'hall',
      title: 'Hall Dashboard'
    }
  },
  {
    path: '/hall/calendar',
    name: 'hall.calendar',
    component: HallDashboard,
    meta: {
      requiresAuth: true,
      role: 'hall',
      title: 'Lịch đặt bàn'
    }
  },
  {
    path: '/hall/reservation-detail/:id?',
    name: 'hall.reservation-detail',
    component: HallDashboard,
    meta: {
      requiresAuth: true,
      role: 'hall',
      title: 'Chi tiết đặt bàn'
    }
  },
  {
    path: '/hall/floor-plan',
    name: 'hall.floor-plan',
    component: HallDashboard,
    meta: {
      requiresAuth: true,
      role: 'hall',
      title: 'Sơ đồ bàn'
    }
  },
  {
    path: '/hall/order-menu',
    name: 'hall.order-menu',
    component: HallDashboard,
    meta: {
      requiresAuth: true,
      role: 'hall',
      title: 'Chọn món'
    }
  }
]

export default hallRoutes
