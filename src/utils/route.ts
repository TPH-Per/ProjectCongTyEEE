import type { RouteLocationRaw } from 'vue-router'
import type { UserRole } from '@/types/database'

/**
 * REVISED MVP PLAN (6 Roles)
 * 1. customer
 * 2. hall
 * 3. kitchen
 * 4. purchasing
 * 5. accounting
 * 6. admin
 */
export function getHomeRouteForRole(role: UserRole | string | null | undefined): RouteLocationRaw {
  switch (role) {
    case 'superadmin':
      return { name: 'superadmin-dashboard' }
    case 'admin':
      return { name: 'admin-dashboard' }
    case 'manager':
      return { name: 'manager-dashboard' }
    case 'reception':
      return { name: 'reception-dashboard' }
    case 'staff':
      return { name: 'staff-floor-plan' }
    case 'hall':
      return { name: 'hall-floor-plan' }
    case 'kitchen':
      return { name: 'kitchen-kds' }
    case 'procurement':
    case 'procurement_manager':
    case 'procurement_staff':
    case 'purchasing':
      return { name: 'purchasing-receipts' }
    case 'accounting':
      return { name: 'accounting-invoices' }
    case 'crm':
      return { name: 'crm-serving-tables' }
    case 'customer':
      return { name: 'tablet-idle' }
    default:
      return { name: 'login' }
  }
}

export function getFallbackRouteForRole(
  role: UserRole | string | null | undefined,
): RouteLocationRaw {
  return getHomeRouteForRole(role)
}
