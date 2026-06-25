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
 * that doesn't allow their role. Send them to their OWN portal landing
 * (via getHomeRouteForRole) — NOT to manager-dashboard, because
 * /manager/* is restricted to admin + manager only. Returning manager
 * for a staff/reception/kitchen user would re-trigger this guard and
 * loop infinitely ("infinite redirect" Stack Overflow).
 */
export function getFallbackRouteForRole(
  role: UserRole | null | undefined,
): RouteLocationRaw {
  return getHomeRouteForRole(role)
}
