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
    case 'admin':
      return { name: 'admin-dashboard' }
    case 'manager':
      return { name: 'manager-dashboard' }
    case 'cashier':
      return { name: 'reception-dashboard' }
    case 'customer':
      return { name: 'CustomerHome' }
    default:
      return { name: 'login' }
  }
}

export function getFallbackRouteForRole(
  role: UserRole | string | null | undefined,
): RouteLocationRaw {
  return getHomeRouteForRole(role)
}
