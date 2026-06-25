import type { RouteLocationRaw } from 'vue-router'
import type { UserRole } from '@/types/database'

/**
 * Map a user role to its default landing route.
 *
 * `admin` is treated as the supervisor: lands on the manager dashboard
 * (the cross-portal overview) unless they explicitly open a sub-portal.
 * Other roles land on their primary workspace.
 *
 * Unknown / missing role falls back to /login so the router guard can
 * deal with the unauthenticated case.
 */
export function getHomeRouteForRole(role: UserRole | null | undefined): RouteLocationRaw {
  switch (role) {
    case 'admin':
      return { name: 'admin-dashboard' }
    case 'manager':
      return { name: 'manager-dashboard' }
    case 'reception':
      return { name: 'reception-dashboard' }
    case 'staff':
      return { name: 'staff-floor-plan' }
    case 'kitchen':
      return { name: 'kitchen-kds' }
    default:
      return { name: 'login' }
  }
}

/**
 * Where to send a user who is signed in but trying to reach a route
 * that doesn't allow their role. We use manager-dashboard as the
 * "neutral" landing because it works for both admin (supervisor) and
 * any other role.
 */
export function getFallbackRouteForRole(
  role: UserRole | null | undefined,
): RouteLocationRaw {
  if (role === 'admin') return { name: 'admin-dashboard' }
  return { name: 'manager-dashboard' }
}
